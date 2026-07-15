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

local function extmark_details(output)
  local marks = vim.api.nvim_buf_get_extmarks(output.bufnr, output.namespace, 0, -1, { details = true })
  local details = {}
  for _, mark in ipairs(marks) do
    table.insert(details, {
      row = mark[2],
      start_col = mark[3],
      end_col = mark[4].end_col,
      hl_group = mark[4].hl_group,
    })
  end
  return details
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

output:clear()
output:push("stdout", "\27[31mred\27[0m plain\n")
wait_for_last_line(output, "red plain")
local reset_marks = extmark_details(output)
assert_equal(1, #reset_marks, "SGR reset should stop the active foreground highlight")
assert_equal(0, reset_marks[1].start_col, "the foreground highlight should start at the colored text")
assert_equal(3, reset_marks[1].end_col, "the foreground highlight should end before plain text")

output:clear()
output:push("stdout", "\27[31;44mcolored\27[39m background\27[49m plain\n")
wait_for_last_line(output, "colored background plain")
local color_reset_marks = extmark_details(output)
assert_equal(2, #color_reset_marks, "foreground and background resets should produce two styled ranges")
assert_equal(7, color_reset_marks[1].end_col, "SGR 39 should end the combined foreground range")
assert_equal(7, color_reset_marks[2].start_col, "the background-only range should follow SGR 39")
assert_equal(18, color_reset_marks[2].end_col, "SGR 49 should end the remaining background range")

output:clear()
output:push("stdout", "\27[31mred\27[0")
output:push("stdout", "m plain\n")
wait_for_last_line(output, "red plain")
local split_reset_marks = extmark_details(output)
assert_equal(3, split_reset_marks[1].end_col, "a split SGR reset should stop the active style")

vim.api.nvim_set_hl(0, "Normal", { fg = 0xffffff, bg = 0x000000 })
output:clear()
output:push("stdout", "\27[2;38;2;255;255;255mfaint\27[0m\n")
wait_for_last_line(output, "faint")
local faint_marks = extmark_details(output)
local faint_group = faint_marks[1].hl_group
local faint_highlight = vim.api.nvim_get_hl(0, { name = faint_group, link = false })
assert_equal(0x999999, faint_highlight.fg, "faint text should blend its foreground toward Normal background")

vim.api.nvim_set_hl(0, faint_group, {})
vim.api.nvim_exec_autocmds("ColorScheme", { modeline = false })
local restored_highlight = vim.api.nvim_get_hl(0, { name = faint_group, link = false })
assert_equal(0x999999, restored_highlight.fg, "ColorScheme should recreate generated ANSI highlights")

local original_buf = vim.api.nvim_get_current_buf()
local original_win = vim.api.nvim_get_current_win()
vim.api.nvim_win_set_buf(original_win, output.bufnr)
output:configure_window(original_win)
assert_equal(true, vim.wo[original_win].wrap, "output windows should soft-wrap")
assert_equal(true, vim.wo[original_win].linebreak, "output windows should wrap at word boundaries")
vim.api.nvim_win_set_buf(original_win, original_buf)

output:dispose()
print("services-output-tests: ok")
