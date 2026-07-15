local test_file = debug.getinfo(1, "S").source:gsub("^@", "")
local config_root = vim.fs.dirname(vim.fs.dirname(test_file))
package.path = table.concat({
  config_root .. "/lua/?.lua",
  config_root .. "/lua/?/init.lua",
  package.path,
}, ";")

vim.o.columns = 160
vim.o.lines = 30

local output = require("services.output").new({ name = "zoom-test" })
output:push("stdout", string.rep("x", 120) .. "\n")
assert(vim.wait(500, function()
  return vim.api.nvim_buf_get_lines(output.bufnr, -2, -1, false)[1] == string.rep("x", 120)
end), "normal service output should render before zoom")

vim.api.nvim_win_set_buf(0, output.bufnr)
vim.api.nvim_win_set_width(0, 60)
output:configure_window(0)

local snacks_root = vim.fn.stdpath("data") .. "/lazy/snacks.nvim"
vim.opt.rtp:append(snacks_root)
require("snacks").zen.zoom()
assert(Snacks.zen.win and Snacks.zen.win:valid(), "Snacks zoom should open a full-width window")
assert(vim.api.nvim_win_get_buf(Snacks.zen.win.win) == output.bufnr,
  "zoom should display the same service output buffer")
assert(vim.bo[output.bufnr].buftype == "nofile", "service output must not become a terminal buffer")
assert(vim.wo[Snacks.zen.win.win].wrap, "zoomed service logs should soft-wrap")
assert(vim.wo[Snacks.zen.win.win].linebreak, "zoomed service logs should use linebreak")

Snacks.zen.zoom()
output:dispose()
print("services-zoom-tests: ok")
