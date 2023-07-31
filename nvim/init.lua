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

-- 定义函数：执行Markdown预览
function instantMarkdownPreview()
    vim.cmd('InstantMarkdownPreview')
end

-- 定义函数：执行Lua文件预览
function luaPreview()
    vim.cmd('set splitright')
    vim.cmd('vsp')
    vim.cmd('term lua %')
end

-- 根据不同的文件类型执行不同的命令
function executeFileTypeCommands()
    local filetype = vim.bo.filetype

    if filetype == 'markdown' then
        instantMarkdownPreview()
    elseif filetype == 'lua' then
        luaPreview()
    else
        -- 添加其他文件类型的处理，如果需要
    end
end

-- 创建键盘映射，绑定在Normal模式下的R键
vim.api.nvim_set_keymap('n', 'R', '<cmd>lua executeFileTypeCommands()<cr>', { noremap = true, silent = true })

