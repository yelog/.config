local test_file = debug.getinfo(1, "S").source:gsub("^@", "")
local root = vim.fs.dirname(vim.fs.dirname(test_file))
package.path = root .. "/lua/?.lua;" .. package.path

local function equal(expected, actual, message)
  assert(vim.deep_equal(expected, actual), (message or "values differ")
    .. "\nexpected: " .. vim.inspect(expected) .. "\nactual: " .. vim.inspect(actual))
end

local codec = require("custom.properties_codec")
equal("没有配置离线FVT的[{0}]目录", codec.decode([=[\u6CA1\u6709\u914D\u7F6E\u79BB\u7EBFFVT\u7684[{0}]\u76EE\u5F55]=]),
  "decode Chinese without changing placeholders")
equal([=[\\u4E2D]=], codec.decode([=[\\u4E2D]=]), "literal escaped backslashes are not Unicode escapes")
equal([=[\\中]=], codec.decode([=[\\\u4E2D]=]), "odd backslash runs retain their literal prefix")
equal("😀", codec.decode([=[\uD83D\uDE00]=]), "combine UTF-16 surrogate pairs")
equal([=[\uD83D \uDE00 \u12xz \u0020 \u000A \u005C]=],
  codec.decode([=[\uD83D \uDE00 \u12xz \u0020 \u000A \u005C]=]),
  "retain malformed escapes, isolated surrogates, and syntax-sensitive ASCII escapes")

require("custom.java_properties").setup()
local original_encodings = vim.o.fileencodings
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")
local path = dir .. "/messages_zh_CN.properties"
local raw = {
  [=[ONE=\u6CA1\u6709]=],
  [=[TWO=\u4e2d\u6587]=],
  [=[LITERAL=\\u4E2D]=],
  [=[EMOJI=\uD83D\uDE00]=],
}
vim.fn.writefile(raw, path)
vim.cmd.edit(vim.fn.fnameescape(path))
equal({ "ONE=没有", "TWO=中文", raw[3], "EMOJI=😀" }, vim.api.nvim_buf_get_lines(0, 0, -1, false),
  "native file read should expose Chinese in the buffer")
equal(false, vim.bo.modified, "opening a properties file must not mark it modified")
equal(original_encodings, vim.o.fileencodings, "properties detection must restore global fileencodings")
equal(1, vim.fn.search("没有", "nw"), "native slash search should find Chinese")
equal(2, vim.fn.search("中文", "nw"), "native slash search should find lowercase Unicode escapes")
equal(true, vim.b.java_properties_unicode, "decoded buffers should be identifiable by integrations")
local initial_tick = vim.b.changedtick
vim.cmd("silent write")
equal(raw, vim.fn.readfile(path), "no-op save must preserve exact original escape spellings")
equal(initial_tick, vim.b.changedtick, "saving must not mutate the buffer or its undo history")

vim.cmd("normal! ggA中文")
vim.cmd("silent write")
local saved = vim.fn.readfile(path)
equal([=[ONE=\u6CA1\u6709\u4e2d\u6587]=], saved[1], "edited Chinese should be re-escaped")
equal(raw[2], saved[2], "unmodified lines should preserve lowercase escapes")
equal(false, vim.bo.modified, "successful writes should clear modified")
vim.cmd.undo()
equal("ONE=没有", vim.api.nvim_buf_get_lines(0, 0, 1, false)[1], "undo after save should undo only the user edit")
equal(true, vim.bo.modified, "undoing a saved edit should mark the buffer modified")
vim.cmd("silent write")
equal(raw, vim.fn.readfile(path), "saving an undo should recover the original bytes")

local changedtick = vim.b.changedtick
local copy_path = dir .. "/copy.properties"
vim.cmd("silent 2write " .. vim.fn.fnameescape(copy_path))
equal({ raw[2] }, vim.fn.readfile(copy_path), "range writes should encode Chinese through native file I/O")
equal(changedtick, vim.b.changedtick, "range writes must leave the decoded buffer untouched")
local missing_path = dir .. "/missing/subdir/messages.properties"
local wrote = pcall(vim.cmd, "silent write " .. vim.fn.fnameescape(missing_path))
equal(false, wrote, "a missing target directory must fail normally")
equal({ "ONE=没有", "TWO=中文", raw[3], "EMOJI=😀" }, vim.api.nvim_buf_get_lines(0, 0, -1, false),
  "failed writes must preserve the decoded buffer")
equal(raw, vim.fn.readfile(path), "failed writes must not touch the original file")

vim.cmd("edit! ++enc=utf-8")
equal(raw[1], vim.api.nvim_get_current_line(), "an explicit UTF-8 read should allow inspecting raw escapes")
equal(nil, vim.b.java_properties_unicode, "raw inspection must clear the decoded-buffer marker")
vim.cmd.edit()
equal("ONE=没有", vim.api.nvim_get_current_line(), "normal reopening should re-enable decoded editing")

local utf8_path = dir .. "/utf8.properties"
vim.fn.writefile({ "ONE=中文" }, utf8_path)
vim.cmd.edit(vim.fn.fnameescape(utf8_path))
equal("utf-8", vim.bo.fileencoding, "native UTF-8 properties should keep their encoding")
vim.cmd("normal! A测试")
vim.cmd("silent write")
equal({ "ONE=中文测试" }, vim.fn.readfile(utf8_path), "native UTF-8 files must not be migrated to escapes")

local crlf_path = dir .. "/crlf.properties"
local crlf = "ONE=\\u4E2D\r\nTWO=\\u6587"
vim.fn.writefile(vim.split(crlf, "\n", { plain = true }), crlf_path, "b")
vim.cmd.edit(vim.fn.fnameescape(crlf_path))
equal("dos", vim.bo.fileformat, "detect CRLF after Unicode decoding")
equal(false, vim.bo.endofline, "preserve a missing final newline")
vim.cmd("silent write")
equal(vim.split(crlf, "\n", { plain = true }), vim.fn.readfile(crlf_path, "b"),
  "save CRLF and missing final newline unchanged")

local plain_path = dir .. "/plain.txt"
vim.fn.writefile({ [=[ONE=\u4E2D]=] }, plain_path)
vim.cmd.edit(vim.fn.fnameescape(plain_path))
equal([=[ONE=\u4E2D]=], vim.api.nvim_get_current_line(), "other file types must not be decoded")
equal(original_encodings, vim.o.fileencodings, "normal files must retain the original encoding detection")
vim.cmd("enew!")
vim.fn.delete(dir, "rf")
-- Flush the notification from the intentionally failed write without emitting
-- an expected error after the success message.
local notify = vim.notify
vim.notify = function() end
vim.wait(10, function() return false end)
vim.notify = notify
print("java-properties-tests: ok")
