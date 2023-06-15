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
require("lazy").setup("plugins")

require("utils")
require("utils.key-map")
require("utils.custom-color")
-- 设置水平分割线样式为 "-"
-- vim.opt.fillchars:append({vert = "|", fold = "~", eob = " ", msgsep = "~", diff = "", foldopen = "▾", foldsep = "│", foldclose = "▸"})

-- 设置垂直分割线样式为 "|"
-- vim.opt.fillchars:append({vert = "|"})


