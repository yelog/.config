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

local search = require("custom.project_search")
search.reset()

assert_equal({}, search.parse_masks(nil), "nil mask should search all files")
assert_equal({}, search.parse_masks("  "), "blank mask should search all files")
assert_equal({ "*.xml", "*.java", "!target/**" }, search.parse_masks(" *.xml, *.java, !target/** "),
  "file masks should be trimmed and preserve exclusions")

local state_a = search.state("/project/a")
assert_equal({ regex = false, case_sensitive = false, whole_word = false, masks = {} }, state_a,
  "new projects should use literal case-insensitive defaults")
state_a.regex = true
state_a.masks = { "*.xml" }
assert_equal(state_a, search.state("/project/a"), "state should persist within a project session")
assert_equal({ regex = false, case_sensitive = false, whole_word = false, masks = {} }, search.state("/project/b"),
  "project search state should be isolated by cwd")

assert_equal({ "--ignore-case" }, search.build_args({ case_sensitive = false, whole_word = false }),
  "default grep should always ignore case")
assert_equal({ "--hidden", "--case-sensitive", "--word-regexp" }, search.build_args({
  case_sensitive = true,
  whole_word = true,
}, { "--hidden" }), "enabled options should append ripgrep flags")

assert_equal("0 matches in 0 files", search.result_summary({}), "empty results should report zero counts")
assert_equal("1 match in 1 file", search.result_summary({ { file = "a.lua" } }),
  "singular counts should be grammatical")
assert_equal("3 matches in 2 files", search.result_summary({
  { file = "a.lua" },
  { file = "a.lua" },
  { file = "b.lua" },
}), "matches should count rows and files should be unique")

print("project-search-tests: ok")
