local test_file = debug.getinfo(1, "S").source:gsub("^@", "")
local root = vim.fn.fnamemodify(vim.fs.dirname(vim.fs.dirname(test_file)), ":p"):gsub("/$", "")
package.path = root .. "/lua/?.lua;" .. package.path

local function equal(expected, actual, message)
  assert(vim.deep_equal(expected, actual), (message or "values differ")
    .. "\nexpected: " .. vim.inspect(expected) .. "\nactual: " .. vim.inspect(actual))
end

local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")
local escaped_path = dir .. "/messages with spaces.properties"
local raw = {
  [=[KEY=\u6CA1\u6709\u914D\u7F6E\u79BB\u7EBFFVT\u7684[{0}]\u76EE\u5F55]=],
  [=[LOWER=\u4e2d\u6587]=],
  [=[MIXED=中\u6587]=],
  [=[EMOJI=\uD83D\uDE00]=],
  [=[LITERAL=\\u4e2d]=],
}
vim.fn.writefile(raw, escaped_path)
vim.fn.writefile({ "PLAIN=中文", "词中文词" }, dir .. "/plain.properties")
vim.fn.writefile({ "普通中文文档" }, dir .. "/notes.txt")
vim.fn.writefile({ [=[RAW=\u4e2d\u6587]=] }, dir .. "/raw.txt")

local search = require("custom.project_search")
local function matches(query, extra)
  local args = search.build_args({ case_sensitive = true, whole_word = false }, {
    "--pre", root .. "/scripts/properties-search", "--pre-glob=*.properties",
  })
  local command = { "rg", "--json", "--no-ignore", "--color=never" }
  vim.list_extend(command, args)
  vim.list_extend(command, extra or {})
  vim.list_extend(command, { "--", query, dir })
  local result = vim.system(command, { text = true }):wait()
  assert(result.code == 0 or result.code == 1, result.stderr)
  local items = {}
  for line in result.stdout:gmatch("[^\n]+") do
    local item = vim.json.decode(line)
    if item.type == "match" then items[#items + 1] = item.data end
  end
  return items
end

local chinese = matches("中文", { "--fixed-strings" })
equal(5, #chinese, "global Chinese search should match escaped, mixed, native UTF-8, and normal text")
equal(1, #matches("没有配置离线FVT", { "--fixed-strings" }), "find Chinese and ASCII mixed in one literal")
equal(1, #matches("没有.*FVT.*目录"), "regex must apply to decoded Chinese")
equal(1, #matches("😀", { "--fixed-strings" }), "search surrogate pairs as one Unicode character")
equal(3, #matches("中文", { "--fixed-strings", "--word-regexp" }), "whole-word matching must use Unicode text")
equal(2, #matches("中文", { "--fixed-strings", "-g", "messages*.properties" }),
  "file masks must apply before preprocessing")
equal(1, #matches("中文", { "--fixed-strings", "-g", "*.txt" }), "other file types remain unmodified")
equal(1, #matches("离线fvt", { "--fixed-strings", "--ignore-case" }), "case toggles must work after decoding")

local directory = matches("目录", { "--fixed-strings" })[1]
equal(1, directory.line_number, "preprocessing must preserve source line numbers")
equal(#"KEY=没有配置离线FVT的[{0}]", directory.submatches[1].start,
  "match columns must use decoded UTF-8 byte positions")
equal(raw, vim.fn.readfile(escaped_path), "global search must not modify disk contents")

local source = search.source()
local effective
local previous = package.loaded["snacks.picker.source.grep"]
package.loaded["snacks.picker.source.grep"] = {
  grep = function(opts) effective = opts end,
}
source.finder({ _project_search_base_args = {}, case_sensitive = false, whole_word = false }, {})
package.loaded["snacks.picker.source.grep"] = previous
assert(vim.tbl_contains(effective.args, "--pre"), "Cmd+Shift+F must enable the properties preprocessor")
assert(vim.tbl_contains(effective.args, "--pre-glob=*.properties"),
  "preprocessing must be limited to properties files")

vim.fn.delete(dir, "rf")
print("properties-search-tests: ok")
