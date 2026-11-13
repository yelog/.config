local test_file = debug.getinfo(1, "S").source:gsub("^@", "")
local config_root = vim.fs.dirname(vim.fs.dirname(test_file))
package.path = table.concat({
  config_root .. "/lua/?.lua",
  config_root .. "/lua/?/init.lua",
  package.path,
}, ";")

local terminal = require("custom.igit_terminal")
local api = vim.api
vim.o.columns = 140
vim.o.lines = 40
assert(not terminal.toggle_maximize(), "ordinary buffers must retain editor zoom")

local temporary = vim.fn.tempname()
vim.fn.mkdir(temporary, "p")
local recorded = temporary .. "/bytes"
local python = {
  "import os, sys, tty",
  "tty.setraw(sys.stdin.fileno())",
  'os.write(sys.stdout.fileno(), b"READY\\n")',
  "while True:",
  "    data = os.read(sys.stdin.fileno(), 4096)",
  "    if not data: break",
  '    with open(sys.argv[1], "ab") as output: output.write(data)',
}
local buffer = api.nvim_create_buf(false, true)
local window = api.nvim_open_win(buffer, true, {
  relative = "editor",
  row = 3,
  col = 7,
  width = 100,
  height = 28,
  border = "rounded",
})
local channel = vim.fn.jobstart({
  "/usr/bin/python3", "-u", "-c", table.concat(python, "\n"), recorded,
}, { term = true })
assert(channel > 0, "the fixture terminal must start")
assert(vim.wait(2000, function()
  return table.concat(api.nvim_buf_get_lines(buffer, 0, -1, false), "\n"):find("READY", 1, true)
end), "the fixture terminal must configure raw input")

assert(not terminal.toggle_maximize(), "other terminal applications must retain editor zoom")
vim.bo[buffer].filetype = "igit"
local geometry = api.nvim_win_get_config(window)
local windows = api.nvim_list_wins()
local expected = ""
for _ = 1, 2 do
  assert(terminal.toggle_maximize(), "the focused IGit terminal must handle maximize")
  expected = expected .. "\27[102;13u"
  assert(vim.wait(1000, function()
    local contents = io.open(recorded, "rb")
    if not contents then return false end
    local actual = contents:read("*a")
    contents:close()
    return actual == expected
  end), "each request must send one exact Cmd+Ctrl+F chord")
  assert(vim.deep_equal(geometry, api.nvim_win_get_config(window)), "the float geometry must stay unchanged")
  assert(vim.deep_equal(windows, api.nvim_list_wins()), "maximizing IGit must not open a Zen window")
  assert(api.nvim_get_current_win() == window, "IGit must retain focus")
end

dofile(config_root .. "/after/ftplugin/igit.lua")
local mapping = vim.fn.maparg("<D-C-f>", "t", false, true)
assert(type(mapping.callback) == "function", "IGit must also accept a directly delivered shortcut")
mapping.callback()
expected = expected .. "\27[102;13u"
assert(vim.wait(1000, function()
  local contents = io.open(recorded, "rb")
  if not contents then return false end
  local actual = contents:read("*a")
  contents:close()
  return actual == expected
end), "the buffer mapping must use the same terminal routing")

local ordinary = api.nvim_create_buf(false, true)
api.nvim_win_set_buf(window, ordinary)
assert(not terminal.toggle_maximize(), "a hidden IGit session must not consume another buffer's shortcut")
api.nvim_win_set_buf(window, buffer)

vim.fn.jobstop(channel)
vim.fn.jobwait({ channel }, 1000)
local notifications = {}
vim.notify = function(message)
  notifications[#notifications + 1] = message
end
assert(terminal.toggle_maximize(), "an exited IGit terminal must not trigger outer zoom")
assert(#notifications == 1, "an exited IGit terminal must report that it is unavailable")
assert(vim.deep_equal(geometry, api.nvim_win_get_config(window)), "an exited terminal must retain float geometry")

api.nvim_win_close(window, true)
api.nvim_buf_delete(buffer, { force = true })
api.nvim_buf_delete(ordinary, { force = true })
vim.fn.delete(temporary, "rf")
print("igit-terminal-tests: ok")
