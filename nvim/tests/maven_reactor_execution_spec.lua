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

local command_builder = {
  build_mvn_cmd = function(pom_xml_path, args)
    return {
      cmd = "mvn",
      args = { "-B", "-N", "--file=" .. pom_xml_path, unpack(args) },
    }
  end,
}

local dispatched
local project_view = {}
local console = {
  execute_command = function(command, args, show_output, callback)
    dispatched = { command = command, args = args, show_output = show_output }
    callback("success")
  end,
}

package.preload["maven.utils.cmd_builder"] = function()
  return command_builder
end
package.preload["maven.ui.projects_view"] = function()
  return project_view
end
package.preload["maven.utils.console"] = function()
  return console
end
package.preload["maven.config"] = function()
  return { options = { console = { show_lifecycle_execution = true } } }
end

local reactor = require("custom.maven_reactor_execution")
local aggregator = { pom_xml_path = "/workspace/pom.xml", modules = { {} } }
local leaf = { pom_xml_path = "/workspace/api/pom.xml", modules = {} }

assert_equal({ "-B", "--file=/workspace/pom.xml", "compile" },
  reactor.build_lifecycle_command(aggregator, "compile").args,
  "aggregator lifecycle commands must allow Maven to traverse reactor modules")
assert_equal({ "-B", "-N", "--file=/workspace/api/pom.xml", "compile" },
  reactor.build_lifecycle_command(leaf, "compile").args,
  "leaf lifecycle commands must preserve upstream non-recursive behavior")

reactor.install()
reactor.install()

local render_calls = 0
local instance = {
  _tree = { render = function() render_calls = render_calls + 1 end },
}
setmetatable(instance, { __index = project_view })
instance:_load_lifecycle_node({ extra = { cmd_arg = "compile" }, state = nil }, aggregator)
vim.wait(100, function() return render_calls == 1 end)
assert_equal({ "mvn", { "-B", "--file=/workspace/pom.xml", "compile" }, true },
  { dispatched.command, dispatched.args, dispatched.show_output },
  "patched lifecycle handler must dispatch the recursive aggregator command")

print("maven-reactor-execution-spec-tests: ok")
