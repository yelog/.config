-- Run with the complete config: nvim --headless -i NONE -n
--   '+lua dofile("nvim/tests/properties_picker_spec.lua")'
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")
local path = dir .. "/messages_zh_CN.properties"
local raw = {
  [=[KEY=\u6CA1\u6709\u914D\u7F6E\u79BB\u7EBFFVT\u7684[{0}]\u76EE\u5F55]=],
  [=[SECOND=\u76EE\u5F55]=],
}
vim.fn.writefile(raw, path)
local ok, err = xpcall(function()
  local picker = require("custom.project_search").open({ cwd = dir, search = "目录", show_delay = 0 })
  assert(vim.wait(8000, function() return not picker:is_active() and #picker:items() == 2 end, 20),
    "picker must find both escaped Chinese occurrences")
  picker.list:view(1)
  picker.preview:show(picker, { force = true })
  assert(vim.wait(3000, function()
    return vim.api.nvim_buf_get_lines(picker.preview.win.buf, 0, 1, false)[1]
      == "KEY=没有配置离线FVT的[{0}]目录"
  end, 20), "preview must decode Chinese")
  local position = vim.deepcopy(picker:current().pos)
  assert(vim.deep_equal(position, { 1, #"KEY=没有配置离线FVT的[{0}]" }),
    "search results must resolve to decoded UTF-8 byte columns")
  assert(vim.deep_equal(position, vim.api.nvim_win_get_cursor(picker.preview.win.win)),
    "preview must highlight the decoded match location")
  picker.list:view(2)
  picker.preview:show(picker, { force = true })
  assert(vim.deep_equal({ 2, #"SECOND=" }, vim.api.nvim_win_get_cursor(picker.preview.win.win)),
    "reusing the preview should preserve decoded columns")
  picker.list:view(1)
  picker.preview:show(picker, { force = true })
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
  picker:action("confirm")
  assert(vim.wait(3000, function()
    return vim.uv.fs_realpath(vim.api.nvim_buf_get_name(0)) == vim.uv.fs_realpath(path)
  end, 20), "confirm must open the original file")
  assert(vim.deep_equal(position, vim.api.nvim_win_get_cursor(0)),
    "jump must use the decoded column rather than the raw escaped column")
  assert(vim.fn.search("没有配置离线FVT", "nw") == 1, "slash search must work after jumping")
  assert(not vim.bo.modified, "search and preview must not modify the buffer")
  assert(vim.deep_equal(raw, vim.fn.readfile(path)), "search and preview must not modify the source file")
end, debug.traceback)
if not ok then print(err) end
vim.cmd("enew!")
vim.fn.delete(dir, "rf")
if ok then print("properties-picker-tests: ok") end
vim.cmd(ok and "qa!" or "cquit")
