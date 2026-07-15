local test_file = debug.getinfo(1, "S").source:gsub("^@", "")
local config_root = vim.fs.dirname(vim.fs.dirname(test_file))
package.path = table.concat({
  config_root .. "/lua/?.lua",
  config_root .. "/lua/?/init.lua",
  package.path,
}, ";")

local function assert_equal(expected, actual, message)
  if not vim.deep_equal(expected, actual) then
    error((message or "values differ")
      .. "\nexpected: " .. vim.inspect(expected)
      .. "\nactual:   " .. vim.inspect(actual))
  end
end

local function wait_for_last_line(output, expected)
  assert(vim.wait(500, function()
    if not vim.api.nvim_buf_is_valid(output.bufnr) then return false end
    local lines = vim.api.nvim_buf_get_lines(output.bufnr, -2, -1, false)
    return lines[1] == expected
  end), "timed out waiting for rendered output")
end

local output = require("services.output").new({ limit = 3, name = "output-test" })
assert_equal("nofile", vim.bo[output.bufnr].buftype, "output should use a normal nofile buffer")
assert_equal(false, vim.bo[output.bufnr].modifiable, "output should be immutable outside renderer writes")

output:push("stdout", "\27[31mred")
output:push("stdout", " text\27[0m\n")
wait_for_last_line(output, "red text")
assert_equal({ "red text" }, vim.api.nvim_buf_get_lines(output.bufnr, 0, -1, false),
  "split ANSI output should be rendered as clean text")
local red_marks = vim.api.nvim_buf_get_extmarks(output.bufnr, output.namespace, 0, -1, { details = true })
assert(#red_marks > 0, "ANSI text should produce highlight extmarks")

output:push("stdout", "\27[38;5;196mindexed\27[0m\n")
output:push("stdout", "\27[38;2;10;20;30mrgb\27[0m\n")
wait_for_last_line(output, "rgb")
local color_marks = vim.api.nvim_buf_get_extmarks(output.bufnr, output.namespace, 0, -1, { details = true })
assert(#color_marks >= 3, "16-color, indexed-color, and RGB spans should all be highlighted")

output:push("stderr", "\27[32mstderr")
output:push("stdout", " plain\n")
output:push("stderr", " green\27[0m\n")
wait_for_last_line(output, "stderr green")
assert_equal({ "rgb", " plain", "stderr green" }, vim.api.nvim_buf_get_lines(output.bufnr, 0, -1, false),
  "streams should preserve independent ANSI state and FIFO output retention")

output:push("stdout", "\27[35")
output:push("stdout", "mviolet\27[0m\n")
wait_for_last_line(output, "violet")
assert_equal({ " plain", "stderr green", "violet" }, vim.api.nvim_buf_get_lines(output.bufnr, 0, -1, false),
  "SGR control sequences split across chunks should be decoded")

output:push("stdout", "unfinished")
output:flush("stdout")
wait_for_last_line(output, "unfinished")
assert_equal({ "stderr green", "violet", "unfinished" }, vim.api.nvim_buf_get_lines(output.bufnr, 0, -1, false),
  "flushing should render a final unterminated line")

local original_buf = vim.api.nvim_get_current_buf()
local original_win = vim.api.nvim_get_current_win()
vim.api.nvim_win_set_buf(original_win, output.bufnr)
output:configure_window(original_win)
assert_equal(true, vim.wo[original_win].wrap, "output windows should soft-wrap")
assert_equal(true, vim.wo[original_win].linebreak, "output windows should wrap at word boundaries")
vim.api.nvim_win_set_buf(original_win, original_buf)

output:dispose()
print("services-output-tests: ok")
