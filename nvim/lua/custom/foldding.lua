vim.o.foldcolumn = '0'
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true
vim.o.foldmethod = 'expr'
vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]
vim.o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

local ts = vim.treesitter
-- Source: https://www.reddit.com/r/neovim/comments/1fzn1zt/custom_fold_text_function_with_treesitter_syntax/
local function fold_virt_text(result, start_text, lnum)
  local text = ''
  local hl
  for i = 1, #start_text do
    local char = start_text:sub(i, i)
    local captured_highlights = ts.get_captures_at_pos(0, lnum, i - 1)
    local outmost_highlight = captured_highlights[#captured_highlights]
    if outmost_highlight then
      local new_hl = '@' .. outmost_highlight.capture
      if new_hl ~= hl then
        -- as soon as new hl appears, push substring with current hl to table
        table.insert(result, { text, hl })
        text = ''
        hl = nil
      end
      text = text .. char
      hl = new_hl
    else
      text = text .. char
    end
  end
  table.insert(result, { text, hl })
end
function _G.custom_foldtext()
  local start_text = vim.fn.getline(vim.v.foldstart):gsub('\t', string.rep(' ', vim.o.tabstop))
  local nline = vim.v.foldend - vim.v.foldstart
  local result = {}
  fold_virt_text(result, start_text, vim.v.foldstart - 1)
  table.insert(result, { ' ... ↙ ' .. nline .. ' lines', 'DapBreakpointCondition' })
  return result
end

vim.opt.foldtext = 'v:lua.custom_foldtext()'

local M = {}

local ts_filetypes = {
  typescript = true,
  typescriptreact = true,
}

local function is_typescript(bufnr)
  local ft = vim.bo[bufnr].filetype
  return ts_filetypes[ft] or false
end

local function find_first_import_line(bufnr)
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local last = math.min(line_count, 200)
  local in_block_comment = false
  for i = 0, last - 1 do
    local line = vim.api.nvim_buf_get_lines(bufnr, i, i + 1, false)[1]
    if not line then
      break
    end
    if in_block_comment then
      if line:find('%*/') then
        in_block_comment = false
      end
    elseif line:match('^%s*/%*') then
      if not line:find('%*/') then
        in_block_comment = true
      end
    elseif line:match('^%s*//') or line:match('^%s*$') then
      -- skip single line comments and blank lines
    elseif line:match('^%s*import%f[%s{(]') then
      return i + 1
    else
      return nil
    end
  end
  return nil
end

local function fold_ts_imports(bufnr, try)
  try = try or 1
  if try > 5 then
    return
  end
  if not vim.api.nvim_buf_is_loaded(bufnr) or not is_typescript(bufnr) then
    return
  end
  local line = find_first_import_line(bufnr)
  if not line then
    return
  end
  local wins = vim.fn.win_findbuf(bufnr)
  if not wins or #wins == 0 then
    return
  end
  local succeeded = false
  for _, win in ipairs(wins) do
    vim.api.nvim_win_call(win, function()
      local view = vim.fn.winsaveview()
      local level = vim.fn.foldlevel(line)
      if level == 0 then
        vim.fn.winrestview(view)
        return
      end
      if vim.fn.foldclosed(line) == -1 then
        vim.api.nvim_win_set_cursor(0, { line, 0 })
        vim.cmd('silent! normal! zc')
      end
      vim.fn.winrestview(view)
      succeeded = true
    end)
  end
  if not succeeded then
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_loaded(bufnr) then
        fold_ts_imports(bufnr, try + 1)
      end
    end, 80 * try)
  end
end

function M.schedule_ts_import_fold(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not is_typescript(bufnr) then
    return
  end
  vim.defer_fn(function()
    fold_ts_imports(bufnr, 1)
  end, 50)
end

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'typescript', 'typescriptreact' },
  callback = function(args)
    M.schedule_ts_import_fold(args.buf)
  end,
})

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    if is_typescript(args.buf) then
      M.schedule_ts_import_fold(args.buf)
    end
  end,
})

return M
