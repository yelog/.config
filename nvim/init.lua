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
require("lazy").setup("plugins", {
  dev = {
    path = "~/workspace/vi"
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
vim.g.LanguageClient_serverCommands = {
  sql = { 'sql-language-server', 'up', '--method', 'stdio' },
}
-- 设置水平分割线样式为 "-"
-- vim.opt.fillchars:append({vert = "|", fold = "~", eob = " ", msgsep = "~", diff = "", foldopen = "▾", foldsep = "│", foldclose = "▸"})

-- 设置垂直分割线样式为 "|"
-- vim.opt.fillchars:append({vert = "|"})
