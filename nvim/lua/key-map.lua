local map = vim.keymap.set
-- leader 空格无效化
map("", "<Space>", "<Nop>", { desc = "Disable <Space>" })

-- Which-Key 分组提示
local ok, wk = pcall(require, "which-key")
if ok then
  wk.add({
    { "<leader>j", group = "Java" },
    { "<leader>v", group = "Vue" },
    { "<leader>g", group = "Git" },
    { "<leader>l", group = "LSP" },
    { "<leader>f", group = "Find" },
    { "<leader>t", group = "Toggle" },
    { "<leader>s", group = "Split/Session" },
    { "<leader>d", group = "Debug" },
    { "<leader>c", group = "Code" },
    { "<leader>b", group = "Buffer" },
  })
end

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
local format_filetypes_with_eslint = { "javascript", "typescript", "vue" }
local markdown_code_block_filetypes = {
  js = "javascript",
  javascript = "javascript",
  ts = "typescript",
  typescript = "typescript",
  lua = "lua",
  python = "python",
  py = "python",
  json = "json",
  bash = "sh",
  sh = "sh",
}

local markdown_code_block_extensions = {
  javascript = "js",
  typescript = "ts",
  lua = "lua",
  python = "py",
  json = "json",
  sh = "sh",
  vue = "vue",
}

local markdown_code_block_lsp_servers = {
  javascript = "vtsls",
  typescript = "vtsls",
  json = "jsonls",
}

local function has_lsp_formatter(bufnr)
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if client:supports_method("textDocument/formatting", bufnr) then
      return true
    end
  end
  return false
end

local function start_code_block_lsp(bufnr, filetype)
  local server = markdown_code_block_lsp_servers[filetype]
  if not server then
    return
  end

  local config = vim.lsp.config[server]
  if not config then
    return
  end

  vim.lsp.start(config, { bufnr = bufnr })
end

local function find_markdown_code_block()
  local cursor_line = vim.fn.line(".")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local start_line
  local lang
  local fence_marker

  for line_nr = 1, cursor_line do
    local line = lines[line_nr] or ""
    local marker, fence_lang = line:match("^%s*(```+)%s*([%w_-]*)")
    if not marker then
      marker, fence_lang = line:match("^%s*(~~~+)%s*([%w_-]*)")
    end

    if marker then
      if start_line and marker:sub(1, 1) == fence_marker then
        start_line = nil
        lang = nil
        fence_marker = nil
      else
        start_line = line_nr
        lang = fence_lang
        fence_marker = marker:sub(1, 1)
      end
    end
  end

  if not start_line or start_line == cursor_line then
    return nil
  end

  local end_line
  for line_nr = start_line + 1, #lines do
    local close_marker = (lines[line_nr] or ""):match("^%s*(" .. fence_marker .. fence_marker .. fence_marker .. "+)%s*$")
    if close_marker then
      end_line = line_nr
      break
    end
  end

  if not end_line or cursor_line >= end_line then
    return nil
  end

  lang = (lang or ""):lower()
  return {
    lang = markdown_code_block_filetypes[lang] or lang,
    start_line = start_line,
    end_line = end_line,
  }
end

local function format_temp_buffer_sync(lines, filetype)
  local original_win = vim.api.nvim_get_current_win()
  local original_buf = vim.api.nvim_get_current_buf()
  local temp_buf = vim.api.nvim_create_buf(false, true)
  local extension = markdown_code_block_extensions[filetype] or filetype
  local temp_name = vim.fn.getcwd() .. "/.markdown-code-block-" .. temp_buf .. "." .. extension

  vim.api.nvim_buf_set_name(temp_buf, temp_name)
  vim.api.nvim_buf_set_lines(temp_buf, 0, -1, false, lines)
  vim.bo[temp_buf].bufhidden = "wipe"

  local ok, formatted_lines = pcall(function()
    vim.api.nvim_win_set_buf(original_win, temp_buf)
    vim.bo[temp_buf].filetype = filetype
    start_code_block_lsp(temp_buf, filetype)
    vim.wait(2000, function()
      return has_lsp_formatter(temp_buf)
    end, 50)

    if my.is_include(filetype, format_filetypes_with_eslint) and vim.fn.exists(":LspEslintFixAll") == 2 then
      pcall(vim.cmd, "LspEslintFixAll")
    end

    if not has_lsp_formatter(temp_buf) then
      error("no LSP formatter for " .. filetype)
    end

    vim.lsp.buf.format({ async = false, timeout_ms = 3000 })
    return vim.api.nvim_buf_get_lines(temp_buf, 0, -1, false)
  end)

  if vim.api.nvim_win_is_valid(original_win) then
    vim.api.nvim_win_set_buf(original_win, original_buf)
  end
  if vim.api.nvim_buf_is_valid(temp_buf) then
    vim.api.nvim_buf_delete(temp_buf, { force = true })
  end

  if not ok then
    return nil, formatted_lines
  end
  return formatted_lines
end

local function format_markdown_code_block()
  local block = find_markdown_code_block()
  if not block then
    return false
  end

  if block.lang == "" then
    vim.notify("Markdown code block has no language", vim.log.levels.WARN)
    return true
  end

  local lines = vim.api.nvim_buf_get_lines(0, block.start_line, block.end_line - 1, false)
  if #lines == 0 then
    vim.notify("Markdown code block is empty", vim.log.levels.WARN)
    return true
  end

  local formatted_lines, err = format_temp_buffer_sync(lines, block.lang)
  if not formatted_lines then
    vim.notify("Failed to format Markdown code block: " .. tostring(err), vim.log.levels.WARN)
    return true
  end

  vim.api.nvim_buf_set_lines(0, block.start_line, block.end_line - 1, false, formatted_lines)
  return true
end

map("n", "<D-s>", function()
  if vim.bo.filetype == "markdown" then
    if not format_markdown_code_block() then
      Marklive.table_align()
    end
  elseif my.is_include(vim.bo.filetype, format_filetypes_with_eslint) then
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
map("n", "<D-S-i>", function() vim.cmd("Endpoint") end, { desc = "API" })
-- map("n", "<D-S-O>", function() require("fzf-lua").files() end, { desc = "Search file" })
-- 读取“当前”的可视选区文本（不必退出可视模式）
local function get_current_visual_selection()
  local mode = vim.fn.mode()      -- "v" 字符可视, "V" 行可视, "\22" 块可视
  local vpos = vim.fn.getpos("v") -- 可视起点
  local cpos = vim.fn.getpos(".") -- 当前光标（可视终点）

  -- 转 0-based，buf_get_text 需要 [row, col)
  local srow, scol = vpos[2] - 1, vpos[3] - 1
  local erow, ecol = cpos[2] - 1, cpos[3]

  -- 规范化起止（起点应 <= 终点）
  if (erow < srow) or (erow == srow and ecol < scol) then
    srow, erow = erow, srow
    scol, ecol = ecol, scol
  end

  -- 行可视：整行
  if mode == "V" then
    local lines = vim.api.nvim_buf_get_lines(0, srow, erow + 1, false)
    return table.concat(lines, "\n")
  end

  -- 块可视：逐行截取矩形列区间
  if mode == "\22" then
    local start_col = math.min(scol, ecol)
    local end_col   = math.max(scol, ecol)
    local lines     = {}
    for l = srow, erow do
      local txt = vim.api.nvim_buf_get_lines(0, l, l + 1, false)[1] or ""
      -- 注意 end_col 是闭区间，buf_get_text 右边界是开区间，所以 +1
      local seg = vim.api.nvim_buf_get_text(0, l, start_col, l, end_col + 1, {})[1] or ""
      table.insert(lines, seg)
    end
    return table.concat(lines, "\n")
  end

  -- 字符可视（默认）
  local lines = vim.api.nvim_buf_get_text(0, srow, scol, erow, ecol, {})
  return table.concat(lines, "\n")
end

local function sanitize(q)
  if not q then return nil end
  -- 把多空白合一并去首尾空白
  q = q:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
  if q == "" then return nil end
  return q
end

local function open_files_with_optional_query()
  local mode = vim.fn.mode()
  local query

  if mode == "v" or mode == "V" or mode == "\22" then
    query = sanitize(get_current_visual_selection())
    -- 可选：退出可视高亮（不影响已拿到的 query）
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
  end

  require("fzf-lua").files({
    -- fzf-lua 支持用 fzf_opts 传递 --query；也可用 query = query（新版本支持）
    fzf_opts = query and { ["--query"] = query } or nil,
    query = query, -- 若你的 fzf-lua 版本支持，保留这行更直观
    git_icons = true,
  })
end

-- Normal：正常打开
map("n", "<D-S-O>", open_files_with_optional_query, { desc = "Search file (fzf-lua)" })
-- Visual：带选区作为初始查询
map("x", "<D-S-O>", open_files_with_optional_query, { desc = "Search file with selection (fzf-lua)" })
map("n", "<leader>ff", function() require("fzf-lua").files() end, { desc = "Search file" })
map("n", "<leader>fb", function() require("fzf-lua").buffers() end, { desc = "Search buffers" })

map("n", "gd", function()
  if require('i18n').i18n_definition() then
    return
  end
  if require('i18n').i18n_definition_next_locale() then
    return
  end
  require('snacks').picker.lsp_definitions()
end
, { desc = "goto definition" }) --use telescope instead
-- map("n", "gd", function() require("fzf-lua").lsp_definitions() end, { desc = "Goto definition" })
-- vim.keymap.set('n', 'gd', function()
--   if require('i18n').i18n_definition() then
--     return
--   end
--   if require('i18n').i18n_definition_next_locale() then
--     return
--   end
--   require("fzf-lua").lsp_definitions()
-- end, { desc = 'i18n or LSP definition' })
map("n", "gD", function() require('snacks').picker.lsp_implementations() end, { desc = "Goto implementation" })
-- map("n", "gu", function() require("fzf-lua").lsp_references() end, { desc = "Goto references" })
vim.keymap.set('n', 'gu', function()
  if require('i18n').i18n_key_usages() then
    return
  end
  require("fzf-lua").lsp_references()
end, { desc = 'i18n usages or LSP references' })

map("n", "<leader>fk", function() require("fzf-lua").keymaps() end, { desc = "Search keymaps" })
map("n", "<leader>ft", function() require("fzf-lua").tags() end, { desc = "Search tags" })
map("n", "<leader>fm", function() require("fzf-lua").marks() end, { desc = "Search marks" })
map("n", "<leader>fh", function()
  require("fzf-lua").oldfiles({ prompt = "History❯ ", cwd_only = true, include_current_session = true, git_icons = true })
end, { desc = "Search history" })
map("n", "<D-e>", function()
  require("fzf-lua").oldfiles({ prompt = "History❯ ", cwd_only = true, include_current_session = true, git_icons = true })
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

-- yazi
map("n", "<C-e>", function()
  local yazi_buf = nil
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].filetype == "yazi" then
      yazi_buf = buf
      break
    end
  end
  if yazi_buf then
    vim.api.nvim_buf_delete(yazi_buf, { force = true })
  else
    require("yazi").yazi()
  end
end, { desc = "Toggle Yazi" })
map("n", "<leader>te", function() vim.cmd("Yazi") end, { desc = "Open Yazi" })

-- lazygit
map({"n", "t"}, "<C-g>", function() Snacks.lazygit() end, { desc = "Toggle Lazygit" })

-- toggleterm
map({ "n", "t", "i", "v" }, "<D-2>", function() vim.cmd("ToggleTerm") end, { desc = "Toggle terminal" })

-- overseer (services panel)
map("n", "<leader>oo", function() vim.cmd("OverseerToggle") end, { desc = "Toggle services panel" })
map("n", "<leader>os", function()
  local overseer = require("overseer")
  for _, task in ipairs(overseer.list_tasks({})) do
    if task.metadata and task.metadata.service then
      if not require("custom.java_debug").terminate(task) and task.status == "RUNNING" then
        task:stop()
      end
    end
  end
end, { desc = "Stop all services" })
map("n", "<leader>oa", function()
  local overseer = require("overseer")
  for _, task in ipairs(overseer.list_tasks({})) do
    if task.metadata and task.metadata.service
      and task.status ~= "RUNNING"
      and not require("custom.java_debug").is_debugging(task) then
      task:reset()
      task:start()
    end
  end
end, { desc = "Start all services" })

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
-- map("t", "<C-g>", function() vim.cmd("LLMAppHandler CommitMsg") end, { desc = "Generate commit msg (LLMApp)" })

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

-- Smart zoom: sync with kitty layout toggle
-- Called by kitty sync_zoom.sh via nvim --remote-send
-- @param action string|nil: "zoom" | "unzoom" | nil (toggle)
function SmartZoom(action)
  local win_count = #vim.api.nvim_list_wins()
  if win_count <= 1 and action ~= "unzoom" then
    return
  end

  local zen_valid = Snacks.zen.win ~= nil and Snacks.zen.win:valid()

  if action == "zoom" and not zen_valid then
    Snacks.zen.zoom()
  elseif action == "unzoom" and zen_valid then
    Snacks.zen.zoom()
  elseif action == nil then
    Snacks.zen.zoom()
  end
end

map({ "n", "t" }, "<D-C-f>", function()
  SmartZoom()
end, { desc = "Smart zoom (sync with kitty)" })
