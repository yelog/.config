local test_file = debug.getinfo(1, "S").source:gsub("^@", "")
local config_root = vim.fs.dirname(vim.fs.dirname(test_file))

local function assert_equal(expected, actual, message)
  if not vim.deep_equal(expected, actual) then
    error((message or "values differ")
      .. "\nexpected: " .. vim.inspect(expected)
      .. "\nactual:   " .. vim.inspect(actual))
  end
end

local function read(relative_path)
  local lines = vim.fn.readfile(config_root .. "/" .. relative_path)
  return table.concat(lines, "\n")
end

local function assert_contains(text, needle, message)
  assert(text:find(needle, 1, true), message .. "\nmissing: " .. needle)
end

local captured_options
local apply_current_calls = 0
local setup_order = {}
package.preload["maven"] = function()
  return {
    setup = function(options)
      captured_options = options
      table.insert(setup_order, "maven")
    end,
  }
end
package.preload["custom.maven_project_tree"] = function()
  return {
    install = function()
      table.insert(setup_order, "project_tree")
    end,
  }
end
package.preload["custom.maven_reactor_execution"] = function()
  return {
    install = function()
      table.insert(setup_order, "reactor_execution")
    end,
  }
end
package.preload["custom.maven_profiles"] = function()
  return {
    apply_current = function()
      apply_current_calls = apply_current_calls + 1
      table.insert(setup_order, "profiles")
    end,
  }
end

local spec = dofile(config_root .. "/lua/plugins/panel/maven.lua")

assert_equal("oclay1st/maven.nvim", spec[1], "Maven dashboard should use the selected upstream plugin")
assert_equal({ "Maven", "MavenExec", "MavenInit", "MavenFavorites" }, spec.cmd,
  "upstream Maven commands should trigger lazy loading")
assert_equal({ "MunifTanjim/nui.nvim" }, spec.dependencies, "Maven dashboard should reuse NUI")
assert_equal("mvn", spec.opts.mvn_executable, "Maven dashboard should use the installed Maven executable")
assert_equal(5, spec.opts.project_scanner_depth, "Maven scanner depth should cover common multi-module projects")
assert_equal("right", spec.opts.projects_view.position, "Maven dashboard should open on the right")
assert_equal(55, spec.opts.projects_view.size, "Maven dashboard should reserve a compact sidebar width")

spec.config(nil, spec.opts)
assert_equal(spec.opts, captured_options, "Maven setup should receive the configured options")
assert_equal({ "maven", "project_tree", "reactor_execution", "profiles" }, setup_order,
  "Maven setup should install hierarchy and reactor adapters before applying stored profiles")
assert_equal(1, apply_current_calls, "Maven setup should apply the stored profile after configuration")

local init = read("init.lua")
local keymaps = read("lua/key-map.lua")
local tools = read("lua/plugins/tools.lua")
assert_contains(init, 'require("custom.maven_profiles").setup()', "profile helper should register its commands at startup")
assert_contains(tools, 'vim.g.rooter_buftypes = { "" }', "Rooter should ignore NUI nofile buffers")
assert_contains(keymaps, '{ "<leader>o", group = "Operations" }', "Which-Key should expose Maven under Operations")
assert_contains(keymaps, 'require("custom.maven_profiles").open_dashboard()',
  "Maven panel should resolve the current project's root before opening")
assert_contains(keymaps, 'map("n", "<leader>op", "<cmd>MavenProfiles<cr>"', "Maven profile picker should have a mapping")
assert_contains(keymaps, 'require("custom.maven_profiles").open_execution()',
  "Maven execution should resolve the current project's root before opening")
assert_contains(keymaps, 'require("custom.maven_profiles").open_favorites()',
  "Maven favorites should resolve the current project's root before opening")

print("maven-plugin-spec-tests: ok")
