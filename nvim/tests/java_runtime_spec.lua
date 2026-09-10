local test_file = debug.getinfo(1, "S").source:gsub("^@", "")
local config_root = vim.fs.dirname(vim.fs.dirname(test_file))
package.path = table.concat({
  config_root .. "/lua/?.lua",
  config_root .. "/lua/?/init.lua",
  package.path,
}, ";")

local function assert_equal(expected, actual, message)
  if not vim.deep_equal(expected, actual) then
    error(
      (message or "values differ") .. "\nexpected: " .. vim.inspect(expected) .. "\nactual:   " .. vim.inspect(actual)
    )
  end
end

local java_runtime = require("custom.java_runtime")
local versions = {
  ["/jdk8"] = 8,
  ["/jdk11"] = 11,
  ["/jdk17"] = 17,
  ["/jdk21"] = 21,
  ["/missing"] = nil,
}
local opts = {
  is_java_home = function(home)
    return versions[home] ~= nil
  end,
  version = function(home)
    return versions[home]
  end,
}

local runtimes, launcher = java_runtime.discover({
  JAVA_HOME = "/jdk17",
  JAVA_HOME_8 = "/jdk8",
  JAVA_HOME_11 = "/jdk11",
  JAVA_HOME_17 = "/jdk17",
  JAVA_HOME_21 = "/jdk21",
}, opts)

assert_equal("/jdk21", launcher, "JDTLS should launch with Java 21")
assert_equal({
  { name = "JavaSE-1.8", path = "/jdk8" },
  { name = "JavaSE-11", path = "/jdk11" },
  { name = "JavaSE-17", path = "/jdk17" },
  { name = "JavaSE-21", path = "/jdk21", default = true },
}, runtimes, "Project runtimes should be ordered, deduplicated, and have exactly one default")

local defaults = vim.tbl_filter(function(runtime)
  return runtime.default == true
end, runtimes)
assert_equal(1, #defaults, "Exactly one Java runtime should be default")

local fallback_runtimes, fallback_launcher = java_runtime.discover({ JAVA_HOME = "/jdk21" }, opts)
assert_equal("/jdk21", fallback_launcher, "JAVA_HOME should be accepted when it is Java 21")
assert_equal(
  { { name = "JavaSE-21", path = "/jdk21", default = true } },
  fallback_runtimes,
  "JAVA_HOME should not be mislabeled or duplicated"
)

local sdkman_runtimes, sdkman_launcher = java_runtime.discover({ JAVA_HOME = "/jdk17" }, {
  sdkman_homes = { "/jdk17", "/jdk21" },
  is_java_home = opts.is_java_home,
  version = opts.version,
})
assert_equal("/jdk21", sdkman_launcher, "SDKMAN Java 21 should launch JDTLS when JAVA_HOME is Java 17")
assert_equal(
  {
    { name = "JavaSE-17", path = "/jdk17" },
    { name = "JavaSE-21", path = "/jdk21", default = true },
  },
  sdkman_runtimes,
  "SDKMAN Java 21 should be added without replacing the Java 17 project runtime"
)

local _, explicit_launcher = java_runtime.discover({
  JAVA_HOME = "/jdk17",
  NVIM_JAVA_HOME = "/jdk21-explicit",
}, {
  sdkman_homes = { "/jdk21" },
  is_java_home = function(home) return home == "/jdk21-explicit" or opts.is_java_home(home) end,
  version = function(home) return home == "/jdk21-explicit" and 21 or opts.version(home) end,
})
assert_equal("/jdk21-explicit", explicit_launcher, "NVIM_JAVA_HOME should override SDKMAN Java")

local old_runtimes, old_launcher = java_runtime.discover({ JAVA_HOME = "/jdk17" }, opts)
assert_equal(nil, old_launcher, "JDTLS should not launch on a Java version older than 21")
assert_equal(
  { { name = "JavaSE-17", path = "/jdk17" } },
  old_runtimes,
  "Older Java should remain available as a project runtime"
)

local invalid_runtimes, invalid_launcher = java_runtime.discover({ JAVA_HOME = "/missing" }, opts)
assert_equal({}, invalid_runtimes, "Invalid Java homes should be ignored")
assert_equal(nil, invalid_launcher, "Invalid Java homes should not become launchers")

print("java-runtime-tests: ok")
