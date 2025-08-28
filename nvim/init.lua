vim.api.nvim_command("source ~/.config/nvim/base.vim")
-- leader
vim.g.mapleader = " "
-- add plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
require("utils")

-- Auto load plugins and subspecs
local function get_plugin_specs()
  local plugin_dir = vim.fn.stdpath("config") .. "/lua/plugins"
  local files = vim.fn.globpath(plugin_dir, "**/*.lua", true, true)

  local specs = {}
  for _, file in ipairs(files) do
    local rel_path = file:gsub(plugin_dir .. "/", ""):gsub("%.lua$", "")
    local module_name = "plugins." .. rel_path:gsub("/", ".")
    table.insert(specs, { import = module_name })
  end

  return specs
end

require("lazy").setup({
  spec = get_plugin_specs(),
  dev = {
    path = "~/workspace/vi"
  },
  checker = {
    enabled = false
  }
})

-- Check if the terminal is WezTerm
vim.api.nvim_set_keymap('n', '<leader>tp', ':lua print(os.getenv("WEZTERM_EXECUTABLE"))<CR>',
  { noremap = true, silent = true, desc = "Check Terminal" })

if my.is_wezterm() then
  require("key-map-wezterm")
else
  require("key-map")
end
require("custom-color")
require("custom.run-file")
require("custom.foldding")
vim.g.LanguageClient_serverCommands = {
  sql = { 'sql-language-server', 'up', '--method', 'stdio' },
}
-- 设置水平分割线样式为 "-"
-- vim.opt.fillchars:append({vert = "|", fold = "~", eob = " ", msgsep = "~", diff = "", foldopen = "▾", foldsep = "│", foldclose = "▸"})

-- 设置垂直分割线样式为 "|"
-- vim.opt.fillchars:append({vert = "|"})

-- vim.api.nvim_create_autocmd({ "VimEnter", "VimResume" }, {
--   group = vim.api.nvim_create_augroup("KittySetVarVimEnter", { clear = true }),
--   callback = function()
--     io.stdout:write("\x1b]1337;SetUserVar=in_editor=MQo\007")
--   end,
-- })
--
-- vim.api.nvim_create_autocmd({ "VimLeave", "VimSuspend" }, {
--   group = vim.api.nvim_create_augroup("KittyUnsetVarVimLeave", { clear = true }),
--   callback = function()
--     io.stdout:write("\x1b]1337;SetUserVar=in_editor\007")
--   end,
-- })

-- 进入 Neovim 时触发 kitty 标题更新
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.fn.system("sh ~/.config/kitty/set_nvim_title.sh")
  end
})

-- fix throw error when open java file
vim.g.java_ignore_markdown = 1
