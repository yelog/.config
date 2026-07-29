local test_file = debug.getinfo(1, "S").source:gsub("^@", "")
local config_root = vim.fs.dirname(vim.fs.dirname(test_file))
package.path = table.concat({ config_root .. "/lua/?.lua", config_root .. "/lua/?/init.lua", package.path }, ";")

local function assert_equal(expected, actual, message)
  if not vim.deep_equal(expected, actual) then
    error((message or "values differ") .. "\nexpected: " .. vim.inspect(expected) .. "\nactual: " .. vim.inspect(actual))
  end
end

local root = vim.fn.tempname()
vim.fn.mkdir(root .. "/.nvim", "p")
local launch_config = require("services.launch_config")

assert_equal({}, launch_config.get(root, "springboot::orders"), "missing configuration should be empty")
assert(launch_config.set(root, "springboot::orders", { vmArgs = "-Xmx1g", env = { LOG_LEVEL = "DEBUG" } }),
  "service configuration should persist")
assert_equal({ vmArgs = "-Xmx1g", env = { LOG_LEVEL = "DEBUG" } }, launch_config.get(root, "springboot::orders"),
  "stored service configuration should round-trip")

vim.fn.writefile({ vim.json.encode({
  defaults = { env = { REGION = "local" }, programArgs = "--trace" },
  services = { ["springboot::orders"] = { vmArgs = "-Xmx2g", env = { LOG_LEVEL = "INFO" } } },
}) }, root .. "/.nvim/services.json")
assert_equal({
  vmArgs = "-Xmx2g",
  programArgs = "--trace",
  env = { REGION = "local", LOG_LEVEL = "INFO" },
}, launch_config.get(root, "springboot::orders"), "defaults should merge with service overrides")

vim.fn.writefile({ "not json" }, root .. "/.nvim/services.json")
assert_equal({}, launch_config.get(root, "springboot::orders"), "invalid configuration should be ignored")

vim.fn.delete(root, "rf")
print("services-launch-config-tests: ok")
