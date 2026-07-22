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

local model = require("custom.maven_dependency_model")
local dependencies = {
  { id = "a", group_id = "org.demo", artifact_id = "root", version = "1.0", scope = "compile" },
  { id = "b", parent_id = "a", group_id = "org.demo", artifact_id = "shared", version = "2.0", scope = "compile" },
  { id = "c", parent_id = "a", group_id = "org.demo", artifact_id = "test-only", version = "1.0", scope = "test" },
  { id = "d", group_id = "org.other", artifact_id = "second", version = "1.0", scope = "compile" },
  { id = "e", parent_id = "d", group_id = "org.demo", artifact_id = "shared", version = "2.0", scope = "compile", is_duplicate = true },
  { id = "f", parent_id = "d", group_id = "org.bad", artifact_id = "conflicted", version = "1.5", scope = "runtime", conflict_version = "2.0" },
}

local graph = model.index(dependencies)

assert_equal({ "a", "d" }, graph.roots, "roots should preserve Maven occurrence order")
assert_equal({ "b", "c" }, graph.children.a, "children should be indexed by occurrence")
assert_equal({ "a", "b" }, model.path_for_id(graph, "b"), "a dependency path should include all ancestors")
assert_equal({ { "a", "b" }, { "d", "e" } }, model.paths(graph, "org.demo:shared"),
  "coordinate paths should include every occurrence")

local tree = model.visible_tree(graph, { query = "shared" })
assert_equal({ "a", "b", "d", "e" }, tree, "tree filtering should preserve matching paths")

tree = model.visible_tree(graph, { hide_test = true })
assert_equal({ "a", "b", "d", "e", "f" }, tree, "hiding test scope should remove test nodes")

local list = model.visible_list(graph, {})
assert_equal({ "f", "a", "b", "c", "d" }, list,
  "list mode should deduplicate coordinates and sort by coordinate")

list = model.visible_list(graph, { conflicts_only = true })
assert_equal({ "f" }, list, "conflict mode should show only Maven conflict entries")

list = model.visible_list(graph, { query = "runtime" })
assert_equal({ "f" }, list, "search should match dependency scope")

print("maven-dependency-model-tests: ok")
