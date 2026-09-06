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

vim.opt.rtp:append("/Users/yelog/workspace/vi/maven.nvim")
local model = require("maven.dependencies.model")
local dependencies = {
  { id = "a", group_id = "org.demo", artifact_id = "root", version = "1.0", scope = "compile", size = 10 },
  { id = "b", parent_id = "a", group_id = "org.demo", artifact_id = "shared", version = "2.0", scope = "compile", size = 20 },
  { id = "c", parent_id = "a", group_id = "org.demo", artifact_id = "test-only", version = "1.0", scope = "test", size = 5 },
  { id = "d", group_id = "org.other", artifact_id = "second", version = "1.0", scope = "compile", size = 30 },
  { id = "e", parent_id = "d", group_id = "org.demo", artifact_id = "shared", version = "2.0", scope = "compile", size = 20, is_duplicate = true },
  { id = "f", parent_id = "d", group_id = "org.bad", artifact_id = "conflicted", version = "1.5", scope = "runtime", size = 40, conflict_version = "2.0" },
}

local graph = model.index(dependencies)

assert_equal({ "a", "d" }, graph.roots, "roots should preserve Maven occurrence order")
assert_equal({ "b", "c" }, graph.children.a, "children should be indexed by occurrence")
assert_equal({ "a", "b" }, model.path_for_id(graph, "b"), "a dependency path should include all ancestors")
assert_equal({ { "a", "b" }, { "d", "e" } }, model.paths(graph, "org.demo:shared"),
  "coordinate paths should include every occurrence")
assert_equal({ direct = 2, resolved = 6, conflicts = 1, size = 125 }, model.summary(graph),
  "summary should expose direct, resolved, conflict, and size totals")
assert_equal({ "b", "a", "c" }, model.ordered_ids(graph, { "a", "b", "c" }, { sort_by_size = true }),
  "size sort should be descending and preserve input order for ties")

local tree = model.visible_tree(graph, { query = "shared" })
assert_equal({ "a", "b", "d", "e" }, tree, "tree filtering should preserve matching paths")
assert_equal({ b = true, e = true }, model.matching_ids(graph, { query = "shared" }),
  "tree filtering should distinguish matching dependencies from their ancestors")
assert_equal({}, model.visible_tree(graph, { query = "missing" }),
  "a query with no matches should leave the renderer an explicit empty state")

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
