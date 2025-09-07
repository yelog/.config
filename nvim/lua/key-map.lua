local map = vim.keymap.set
-- leader 空格无效化
map("", "<Space>", "<Nop>", { desc = "Disable <Space>" })

-- Base
map("n", "Q", "<cmd>qa<cr>", { desc = "Quit" })
map("n", "<up>", "<cmd>res-5<cr>", { desc = "Resize up" })
map("n", "<down>", "<cmd>res+5<cr>", { desc = "Resize down" })
map("n", "<left>", "<cmd>vertical res-5<cr>", { desc = "Resize left" })
map("n", "<right>", "<cmd>vertical res+5<cr>", { desc = "Resize right" })

-- 判断当前分屏类型
local function split_type()
  local win_count = #vim.api.nvim_list_wins()
  if win_count == 1 then
    return "No Split"
  end

  -- 获取当前窗口的宽度和高度
  local current_win = vim.api.nvim_get_current_win()
  local current_width = vim.api.nvim_win_get_width(current_win)
  local current_height = vim.api.nvim_win_get_height(current_win)

  -- 遍历所有窗口，判断分屏方向
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if win ~= current_win then
      local width = vim.api.nvim_win_get_width(win)
      local height = vim.api.nvim_win_get_height(win)

      if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "neo-tree" then
        return "neo-tree"
      elseif current_width == width then
        return "Horizontal Split"
      elseif current_height == height then
        return "Vertical Split"
      end
    end
  end

  return "Unknown Split"
end
map("n", "<c-q>", function()
  local type = split_type()
  if vim.bo.filetype == 'neo-tree' or type == "neo-tree" then
    vim.cmd("Neotree close")
  elseif type == "No Split" or type == 'Unknown Split' then
    vim.cmd("bdelete")
  else
    vim.cmd("q")
  end
end, { desc = "Smart Quit" })

-- plugin
map("n", "<leader>pi", function() vim.cmd("Lazy") end, { desc = "Plugin install (Lazy)" })
map("n", "<leader>li", function() vim.cmd("Mason") end, { desc = "Mason dashboard" })

-- comment.nvim
local api = require('Comment.api')
local esc = vim.api.nvim_replace_termcodes('<ESC>', true, false, true)
map("n", "<D-/>", function() api.toggle.linewise.current() end, { desc = "Toggle comment" })
map("v", "<D-/>", function()
  vim.api.nvim_feedkeys(esc, 'nx', false)
  api.toggle.linewise(vim.fn.visualmode())
end, { desc = "Toggle comment" })

-- format
map("n", "<D-s>", function()
  local eslintFileType = { "javascript", "typescript", "vue" }
  if vim.bo.filetype == "markdown" then
    vim.cmd("TableModeRealign")
  elseif my.is_include(vim.bo.filetype, eslintFileType) then
    vim.cmd("LspEslintFixAll")
  else
    vim.lsp.buf.format({ async = true })
  end
end, { desc = "Format code" })

map({ "n", "v" }, "<leader>ll", function()
  vim.lsp.buf.format({ async = true })
end, { desc = "Format code" })

-- fzf-lua（全部改成 function() ... end）
map("n", "<D-S-M>", function()
  if vim.bo.filetype == "http" then
    require("kulala").search()
  else
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    local supports_document_symbols = false
    for _, client in ipairs(clients) do
      if client.server_capabilities.documentSymbolProvider then
        supports_document_symbols = true
        break
      end
    end
    if supports_document_symbols then
      require("fzf-lua").lsp_document_symbols()
    else
      require("fzf-lua").treesitter()
    end
  end
end, { desc = "Search symbols" })

map("n", "<D-S-O>", function() require("fzf-lua").files() end, { desc = "Search file" })
map("n", "<leader>ff", function() require("fzf-lua").files() end, { desc = "Search file" })
map("n", "<leader>fb", function() require("fzf-lua").buffers() end, { desc = "Search buffers" })
-- map("n", "gd", function() require("fzf-lua").lsp_definitions() end, { desc = "Goto definition" })
vim.keymap.set('n', 'gd', function()
  if not require('i18n.navigation').try_definition() then
    require("fzf-lua").lsp_definitions()
  end
end, { desc = 'i18n or LSP definition' })
;
-- map("n", "gD", function() require("fzf-lua").lsp_implementations() end, { desc = "Goto implementation" })
map("n", "gu", function() require("fzf-lua").lsp_references() end, { desc = "Goto references" })
map("n", "<leader>fk", function() require("fzf-lua").keymaps() end, { desc = "Search keymaps" })
map("n", "<leader>ft", function() require("fzf-lua").tags() end, { desc = "Search tags" })
map("n", "<leader>fm", function() require("fzf-lua").marks() end, { desc = "Search marks" })
map("n", "<leader>fh", function()
  require("fzf-lua").oldfiles({ prompt = "History❯ ", cwd_only = true, include_current_session = true })
end, { desc = "Search history" })
map("n", "<D-e>", function()
  require("fzf-lua").oldfiles({ prompt = "History❯ ", cwd_only = true, include_current_session = true })
end, { desc = "Search history" })
map("n", "<leader>f;", function() require("fzf-lua").builtin() end, { desc = "Search builtin" })
map("n", "<leader>fs", function() require("fzf-lua").live_grep() end, { desc = "Search word" })
map("n", "<D-S-F>", function() require("fzf-lua").live_grep() end, { desc = "Search word" })
map("v", "<D-S-F>", function() require("fzf-lua").grep_visual() end, { desc = "Search word (visual)" })

-- kulala
map("n", "<leader>ce", function() require("kulala").set_selected_env() end, { desc = "Select kulala env" })

-- autosession
map("n", "<leader>sd", function() vim.cmd("Autosession delete") end, { desc = "Delete session" })

-- aerial
map("n", "<leader>ts", function() vim.cmd("AerialToggle") end, { desc = "Toggle structure (Aerial)" })

-- bufferline
map("n", "<c-n>", function() vim.cmd("bnext") end, { desc = "Next buffer" })
map("n", "<c-p>", function() vim.cmd("bprevious") end, { desc = "Prev buffer" })
map("n", "<leader>bo", function() Snacks.bufdelete.other() end, { desc = "Close other buffers" })

-- markdown
map("n", "<leader>tm", function() vim.cmd("TableModeToggle") end, { desc = "Table Mode Toggle" })
map("n", "<leader>md", function() vim.cmd("ObsidianToday") end, { desc = "Goto daily task" })

-- neo-tree
map("n", "<D-1>", function() vim.cmd("Yazi") end, { desc = "Toggle Explorer" })
map("n", "<leader>te", function() vim.cmd("Yazi") end, { desc = "Toggle Explorer" })

-- toggleterm
map({ "n", "t", "i", "v" }, "<D-2>", function() vim.cmd("ToggleTerm") end, { desc = "Toggle terminal" })

-- ChatGPT (avante)
local avanteApi = require("avante.api")
map("i", "<D-k>", "<esc>V<cmd>AvanteEdit<cr>", { desc = "Avante edit" })
map("n", "<D-k>", "V<cmd>AvanteEdit<cr>", { desc = "Avante edit" })
map("v", "<D-k>", function() avanteApi.edit() end, { desc = "Avante edit" })
map({ "i", "n", "v" }, "<D-K>", function() vim.cmd("AvanteChat") end, { desc = "Avante chat" })

-- copilot (保持 function)
map("i", "<right>", function()
  local copilot = require("copilot.suggestion")
  if copilot.is_visible() then
    copilot.accept()
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Right>", true, true, true), "n", true)
  end
end, { desc = "Accept Copilot or move right" })

-- marklive
map({ "n", "v" }, "<CR>", function()
  if vim.bo.filetype == "markdown" then
    vim.cmd("MarkliveTaskToggle")
  end
end, { desc = "Marklive toggle task (markdown only)" })
map("t", "<C-g>", function() vim.cmd("LLMAppHandler CommitMsg") end, { desc = "Generate commit msg (LLMApp)" })

-- smart-splits 全部改 function()
map({ "n", "t" }, "<D-C-h>", function() require("smart-splits").move_cursor_left() end, { desc = "Move left split" })
map({ "n", "t" }, "<D-C-j>", function() require("smart-splits").move_cursor_down() end, { desc = "Move down split" })
map({ "n", "t" }, "<D-C-k>", function() require("smart-splits").move_cursor_up() end, { desc = "Move up split" })
map({ "n", "t" }, "<D-C-l>", function() require("smart-splits").move_cursor_right() end, { desc = "Move right split" })
map("i", "<D-C-h>", function() require("smart-splits").move_cursor_left() end, { desc = "Move left split" })
map("i", "<D-C-j>", function() require("smart-splits").move_cursor_down() end, { desc = "Move down split" })
map("i", "<D-C-k>", function() require("smart-splits").move_cursor_up() end, { desc = "Move up split" })
map("i", "<D-C-l>", function() require("smart-splits").move_cursor_right() end, { desc = "Move right split" })

map({ "n", "t" }, "<D-C-S-h>", function() require("smart-splits").resize_left() end, { desc = "Resize left" })
map({ "n", "t" }, "<D-C-S-j>", function() require("smart-splits").resize_down() end, { desc = "Resize down" })
map({ "n", "t" }, "<D-C-S-k>", function() require("smart-splits").resize_up() end, { desc = "Resize up" })
map({ "n", "t" }, "<D-C-S-l>", function() require("smart-splits").resize_right() end, { desc = "Resize right" })
map("i", "<D-C-S-h>", function() require("smart-splits").resize_left() end, { desc = "Resize left" })
map("i", "<D-C-S-j>", function() require("smart-splits").resize_down() end, { desc = "Resize down" })
map("i", "<D-C-S-k>", function() require("smart-splits").resize_up() end, { desc = "Resize up" })
map("i", "<D-C-S-l>", function() require("smart-splits").resize_right() end, { desc = "Resize right" })
