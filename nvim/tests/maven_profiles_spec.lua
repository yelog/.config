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

local temp_dir = vim.fn.tempname()
vim.fn.mkdir(temp_dir, "p")

local profiles = require("custom.maven_profiles")
local state_path = temp_dir .. "/maven-profiles.json"
local output = table.concat({
  "[INFO] Listing Profiles for Project:",
  "  Profile Id: uat (Active: false, Source: pom)",
  "  Profile Id: dev (Active: true, Source: pom)",
  "  Profile Id: uat (Active: false, Source: settings.xml)",
}, "\n")

local captured_command
profiles.setup({
  path = state_path,
  runner = function(command, _, callback)
    captured_command = command
    callback({ code = 0, stdout = output, stderr = "" })
  end,
})

assert_equal({ "dev", "uat" }, profiles.parse_profiles(output), "profile output should be sorted and unique")

local project_root = temp_dir .. "/project"
vim.fn.mkdir(project_root, "p")
vim.fn.writefile({ "<project />" }, project_root .. "/pom.xml")

assert(profiles.set_profiles(project_root, { "uat", "dev", "dev" }), "profile selection should persist")
assert_equal({ "dev", "uat" }, profiles.get_profiles(project_root), "profile selection should be project-scoped")

local config = {
  options = {
    default_arguments_view = {
      arguments = {
        { arg = "-DskipTests", enabled = true },
        { arg = "-P", value = "legacy", enabled = true },
      },
    },
  },
}

profiles.apply_profiles({ "uat", "dev" }, config)
assert_equal({
  { arg = "-DskipTests", enabled = true },
  { arg = "-P", value = "legacy", enabled = true },
  { arg = "-P", value = "dev,uat", enabled = true, _maven_dashboard_profile = true },
}, config.options.default_arguments_view.arguments, "profile injection should preserve user defaults")

profiles.apply_profiles({}, config)
assert_equal({
  { arg = "-DskipTests", enabled = true },
  { arg = "-P", value = "legacy", enabled = true },
}, config.options.default_arguments_view.arguments, "profile clear should remove only helper arguments")

local listed_profiles
profiles.list_available(project_root, function(err, available)
  assert_equal(nil, err, "Maven profile lookup should not fail")
  listed_profiles = available
end)
assert_equal({ "mvn", "--batch-mode", "--non-recursive", "--file", project_root .. "/pom.xml", "help:all-profiles" },
  captured_command, "profile lookup should use a shell-free Maven command")
assert_equal({ "dev", "uat" }, listed_profiles, "Maven profile lookup should parse command output")

local missing_root = temp_dir .. "/missing"
vim.fn.mkdir(missing_root, "p")
local missing_error
profiles.list_available(missing_root, function(err, available)
  missing_error = err
  assert_equal(nil, available, "missing Maven projects should not return profiles")
end)
assert(missing_error:find("pom.xml", 1, true), "missing Maven project should explain the missing pom.xml")
assert_equal({}, profiles.get_profiles(missing_root), "failed lookup must not mutate selection")

vim.fn.delete(temp_dir, "rf")
print("maven-profile-tests: ok")
