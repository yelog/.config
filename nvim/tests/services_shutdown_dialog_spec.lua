local test_file = debug.getinfo(1, "S").source:gsub("^@", "")
local config_root = vim.fs.dirname(vim.fs.dirname(test_file))
package.path = table.concat({
  config_root .. "/lua/?.lua",
  config_root .. "/lua/?/init.lua",
  package.path,
}, ";")

local dialog = require("services.shutdown_dialog")
local overseer_config = table.concat(vim.fn.readfile(config_root .. "/lua/plugins/panel/overseer.lua"), "\n")

assert(
  overseer_config:find('render_shutdown_status = require("services.shutdown_dialog").render', 1, true),
  "service lifecycle should render shutdown progress in the dialog"
)

local function shutdown_window()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(win).relative == "editor" then return win end
  end
end

local original_cmd = vim.cmd
local redrawn = false
vim.cmd = function(command)
  if command == "redraw!" then
    redrawn = true
    return
  end
  return original_cmd(command)
end
dialog.render(nil, { phase = "closing", text = "◐ 正在关闭服务 1/1 · 0.0s" })
vim.cmd = original_cmd
local win = assert(shutdown_window(), "shutdown should open a centered floating window")
assert(not vim.api.nvim_win_get_config(win).focusable, "shutdown window must not take focus")
assert(redrawn, "shutdown dialog should force a redraw during synchronous exit")
assert(vim.deep_equal({ "正在关闭服务", "", "◐ 正在关闭服务 1/1 · 0.0s", "请稍候，正在终止后台进程" },
  vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false)), "dialog should render closing progress")

dialog.render(nil, { phase = "force", text = "! 正在强制关闭剩余服务" })
assert(vim.deep_equal({ "正在关闭服务", "", "! 正在强制关闭剩余服务", "请稍候，正在终止后台进程" },
  vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false)), "dialog should render force progress")

dialog.render(nil, nil)
assert(not shutdown_window(), "shutdown dialog should close after completion")

print("services-shutdown-dialog-spec-tests: ok")
