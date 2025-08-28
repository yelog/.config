vim.api.nvim_command("source ~/.config/nvim/base.vim")
-- add plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out,                            "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)
-- leader
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

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

require("key-map")
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
