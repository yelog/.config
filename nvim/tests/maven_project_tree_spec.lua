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

local function project(pom_xml_path, root_path, name)
  return {
    pom_xml_path = pom_xml_path,
    root_path = root_path,
    name = name,
    modules = {},
  }
end

local function parser(module_paths)
  return function(pom_xml_path)
    return { module_paths = module_paths[pom_xml_path] or {} }
  end
end

local upstream_project_view = {
  _setup_win_maps = function(self)
    self._win:map("n", "a", function() self.upstream_analysis_opened = true end)
  end,
}
local analyzer_calls = {}

package.preload["maven.ui.projects_view"] = function() return upstream_project_view end
vim.opt.rtp:append("/Users/yelog/workspace/vi/maven.nvim")
package.preload["maven"] = function()
  return {
    open_dependencies = function(...)
      table.insert(analyzer_calls, { ... })
    end,
  }
end

local project_tree = require("maven.project_tree")

local root = project("/workspace/pom.xml", "/workspace", "root")
local api = project("/workspace/api/pom.xml", "/workspace/api", "api")
local service = project("/workspace/api/service/pom.xml", "/workspace/api/service", "service")
local cli = project("/workspace/cli/pom.xml", "/workspace/cli", "cli")

local roots = project_tree.rebuild({ service, cli, api, root }, parser({
  ["/workspace/pom.xml"] = { "api/pom.xml", "cli" },
  ["/workspace/api/pom.xml"] = { "service" },
}))

assert_equal({ root }, roots, "only the Maven aggregator should remain at top level")
assert_equal({ api, cli }, root.modules, "aggregator modules should be sorted and attached once")
assert_equal({ service }, api.modules, "nested module should remain below its direct aggregator")

local alpha = project("/duplicate/alpha/pom.xml", "/duplicate/alpha", "alpha")
local beta = project("/duplicate/beta/pom.xml", "/duplicate/beta", "beta")
local shared = project("/duplicate/shared/pom.xml", "/duplicate/shared", "shared")

roots = project_tree.rebuild({ shared, beta, alpha }, parser({
  ["/duplicate/alpha/pom.xml"] = { "../shared" },
  ["/duplicate/beta/pom.xml"] = { "../shared" },
}))

assert_equal({ alpha, beta }, roots, "a duplicate module declaration must not hide both aggregators")
assert_equal({ shared }, alpha.modules, "the first sorted aggregator should own a duplicate module")
assert_equal({}, beta.modules, "a duplicate module should be attached only once")

local one = project("/cycle/one/pom.xml", "/cycle/one", "one")
local two = project("/cycle/two/pom.xml", "/cycle/two", "two")

roots = project_tree.rebuild({ two, one }, parser({
  ["/cycle/one/pom.xml"] = { "../two" },
  ["/cycle/two/pom.xml"] = { "../one" },
}))

assert_equal({ one, two }, roots, "cyclic module declarations must remain roots")
assert_equal({}, one.modules, "cyclic declarations must not add recursive modules")
assert_equal({}, two.modules, "cyclic declarations must not add recursive modules")

local wrapped_root = project("/wrapped/pom.xml", "/wrapped", "wrapped-root")
local wrapped_child = project("/wrapped/child/pom.xml", "/wrapped/child", "wrapped-child")
local upstream_calls = 0
local sources = {
  scan_projects = function(base_path, callback)
    assert_equal("/wrapped", base_path, "the adapter must preserve the scanner path")
    upstream_calls = upstream_calls + 1
    callback({ wrapped_child, wrapped_root })
    return "upstream scan result"
  end,
}

package.preload["maven.sources"] = function()
  return sources
end
package.preload["maven.parsers.pom_xml_parser"] = function()
  return {
    parse_file = parser({
      ["/wrapped/pom.xml"] = { "child/pom.xml" },
    }),
  }
end

project_tree.install()
local wrapped_scan_projects = sources.scan_projects
project_tree.install()
assert(wrapped_scan_projects == sources.scan_projects, "adapter installation must be idempotent")

local wrapped_roots
local scan_result = sources.scan_projects("/wrapped", function(items)
  wrapped_roots = items
end)

assert_equal("upstream scan result", scan_result, "the adapter must preserve the upstream return value")
assert_equal(1, upstream_calls, "the adapter must call the upstream scanner once")
assert_equal({ wrapped_root }, wrapped_roots, "the installed scanner must rebuild the project tree")
assert_equal({ wrapped_child }, wrapped_root.modules, "the installed scanner must resolve direct POM paths")

local maps = {}
local selected_project = project("/workspace/module/pom.xml", "/workspace/module", "module")
local view = {
  _win = {
    map = function(_, _, key, callback)
      maps[key] = callback
    end,
  },
  _tree = {
    get_node = function()
      return { project_id = "module" }
    end,
  },
  _lookup_project = function(_, id)
    assert_equal("module", id, "the analyzer must use the selected node project")
    return selected_project
  end,
}

upstream_project_view._setup_win_maps(view)
assert(maps.a, "the project view should install an analysis mapping")
maps.a()
assert_equal({ { pom = "/workspace/module/pom.xml" } }, analyzer_calls[1],
  "panel analysis should open the unified analyzer for the selected module POM")

local notifications = {}
local original_notify = vim.notify
vim.notify = function(message, level)
  table.insert(notifications, { message, level })
end
view._tree.get_node = function() return nil end
maps.a()
vim.notify = original_notify

assert_equal(1, #analyzer_calls, "an empty panel selection must not open dependency analysis")
assert_equal("Not project selected", notifications[1][1], "an empty panel selection should explain the problem")

print("maven-project-tree-spec-tests: ok")
