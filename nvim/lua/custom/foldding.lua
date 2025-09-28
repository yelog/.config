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

local fold_targets = {
  typescript = { finder = 'default', max_scan = 200 },
  typescriptreact = { finder = 'default', max_scan = 200 },
  javascript = { finder = 'default', max_scan = 200 },
  javascriptreact = { finder = 'default', max_scan = 200 },
  vue = { finder = 'vue', max_scan = 400 },
  java = {
    finder = 'default',
    max_scan = 200,
    allowed_before = {
      '^%s*package%s',
      '^%s*@[A-Z][A-Za-z]+',
    },
  },
}

local function get_target(bufnr)
  local ft = vim.bo[bufnr].filetype
  return fold_targets[ft], ft
end

local function is_target(bufnr)
  local cfg = get_target(bufnr)
  return cfg ~= nil
end

local function line_import_match(line)
  return line and line:match('^%s*import%f[%s{(]') ~= nil
end

local function should_skip_leading(line)
  if not line then
    return true
  end
  if line:match('^%s*$') then
    return true
  end
  if line:match('^%s*//') then
    return true
  end
  if line:match('^%s*%-%-') then
    return true
  end
  if line:match('^%s*#') then
    return true
  end
  if line:match([[^%s*[;,{]?%s*['"][Uu]se%s+]]) then
    return true
  end
  return false
end

local function find_import_default(bufnr, cfg)
  cfg = cfg or {}
  local allowed = cfg.allowed_before or {}
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local last = math.min(line_count, cfg.max_scan or 200)
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
    else
      if line_import_match(line) then
        return i + 1
      end

      if line:match('^%s*/%*') then
        if not line:find('%*/') then
          in_block_comment = true
        end
      elseif should_skip_leading(line) then
        -- skip
      else
        local allowed_line = false
        for _, pattern in ipairs(allowed) do
          if line:match(pattern) then
            allowed_line = true
            break
          end
        end
        if not allowed_line then
          return nil
        end
      end
    end
  end

  return nil
end

local function find_import_vue(bufnr, cfg)
  cfg = cfg or {}
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local last = math.min(line_count, cfg.max_scan or 400)
  local in_block_comment = false
  local script_open = false

  for i = 0, last - 1 do
    local line = vim.api.nvim_buf_get_lines(bufnr, i, i + 1, false)[1]
    if not line then
      break
    end

    if not script_open then
      if line:find('<script') then
        script_open = true
        local after = line:match('<script[^>]*>(.*)')
        if after and line_import_match(after) then
          return i + 1
        end
      end
    else
      if line:find('</script') then
        return nil
      end

      if in_block_comment then
        if line:find('%*/') then
          in_block_comment = false
        end
      else
        if line_import_match(line) then
          return i + 1
        end

        if line:match('^%s*/%*') then
          if not line:find('%*/') then
            in_block_comment = true
          end
        elseif should_skip_leading(line) then
          -- skip
        elseif line:match('^%s*define') or line:match('^%s*const%s+[_%w]+%s*=') then
          return nil
        else
          return nil
        end
      end
    end
  end

  return nil
end

local import_finders = {
  default = find_import_default,
  vue = find_import_vue,
}

local function find_first_import_line(bufnr)
  local cfg = get_target(bufnr)
  if not cfg then
    return nil
  end
  local finder = import_finders[cfg.finder] or import_finders.default
  return finder(bufnr, cfg)
end

local function fold_imports(bufnr, try)
  try = try or 1
  if try > 5 then
    return
  end
  if not vim.api.nvim_buf_is_loaded(bufnr) or not is_target(bufnr) then
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
        fold_imports(bufnr, try + 1)
      end
    end, 80 * try)
  end
end

function M.schedule_import_fold(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not is_target(bufnr) then
    return
  end
  vim.defer_fn(function()
    fold_imports(bufnr, 1)
  end, 50)
end

vim.api.nvim_create_autocmd('FileType', {
  pattern = {
    'typescript',
    'typescriptreact',
    'javascript',
    'javascriptreact',
    'vue',
    'java',
  },
  callback = function(args)
    M.schedule_import_fold(args.buf)
  end,
})

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    if is_target(args.buf) then
      M.schedule_import_fold(args.buf)
    end
  end,
})

return M
