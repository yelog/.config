vim.o.foldcolumn = '0' -- '0' is not bad
vim.o.foldlevel = 99   -- Using ufo provider need a large value, feel free to decrease the value
vim.o.foldlevelstart = 99
vim.o.foldenable = true
vim.o.foldmethod = 'expr'
vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]
vim.o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

local ts = vim.treesitter
local query = vim.treesitter.query
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

-- 折叠 import 节点
local function fold_imports(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local lang = vim.bo[bufnr].filetype
  local parser = ts.get_parser(bufnr, lang)
  if not parser then return end

  local tree = parser:parse()[1]
  local root = tree:root()

  -- 根据语言选择 import 节点类型
  local import_types = {
    java = "import_declaration",
    typescript = "import_statement",
    tsx = "import_statement",
    javascript = "import_statement",
  }

  local import_type = import_types[lang]
  if not import_type then return end

  -- 构造 query，匹配所有 import 节点
  local q = query.parse(lang, string.format("(%s) @import", import_type))

  for _, match, _ in q:iter_matches(root, bufnr, 0, -1) do
    for id, node in pairs(match) do
      local start_row, _, _, _ = node:range()
      vim.api.nvim_win_set_cursor(0, { start_row + 1, 0 })
      vim.cmd("normal! zc")
    end
  end
end

-- 自动：文件打开时折叠import
vim.api.nvim_create_autocmd("BufWinEnter", {
  pattern = { "*.java", "*.ts", "*.tsx", "*.js" },
  callback = function(args)
    vim.defer_fn(function()
      fold_imports(args.buf)
    end, 100)
  end,
})
