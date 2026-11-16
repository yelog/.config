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
assert_equal({
  { name = "JavaSE-17", path = "/jdk17" },
  { name = "JavaSE-21", path = "/jdk21", default = true },
}, sdkman_runtimes, "SDKMAN Java 21 should be added without replacing the Java 17 project runtime")

local _, explicit_launcher = java_runtime.discover({
  JAVA_HOME = "/jdk17",
  NVIM_JAVA_HOME = "/jdk21-explicit",
}, {
  sdkman_homes = { "/jdk21" },
  is_java_home = function(home)
    return home == "/jdk21-explicit" or opts.is_java_home(home)
  end,
  version = function(home)
    return home == "/jdk21-explicit" and 21 or opts.version(home)
  end,
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

local temp_dir = vim.fn.tempname()
local function make_jdk(name, version)
  local home = temp_dir .. "/" .. name
  vim.fn.mkdir(home .. "/bin", "p")
  vim.fn.writefile({ "#!/bin/sh", "exit 1" }, home .. "/bin/java")
  vim.fn.setfperm(home .. "/bin/java", "rwx------")
  if version then
    vim.fn.writefile({ 'JAVA_VERSION="' .. version .. '"' }, home .. "/release")
  end
  return vim.uv.fs_realpath(home)
end

local java8 = make_jdk("jdk8", "1.8.0_472")
local java17 = make_jdk("jdk17", "17.0.15")
local java21_old = make_jdk("jdk21-old", "21.0.2")
local java21_new = make_jdk("jdk21-new", "21.0.10")
local java25 = make_jdk("jdk25", "25.0.2")
local sdkman_homes = { java8, java17, java21_old, java21_new, java25 }
local original_system = vim.system
local original_readfile = vim.fn.readfile
local version_probes = 0
local release_reads = 0
vim.system = function()
  version_probes = version_probes + 1
  error("release metadata should avoid starting Java")
end
vim.fn.readfile = function(path, ...)
  if path:match("/release$") then
    release_reads = release_reads + 1
  end
  return original_readfile(path, ...)
end

local metadata_env = { JAVA_HOME = java17 }
local metadata_opts = { sdkman_homes = sdkman_homes }
local metadata_runtimes, metadata_launcher = java_runtime.discover(metadata_env, metadata_opts)
assert_equal(
  java21_new,
  metadata_launcher,
  "SDKMAN discovery should prefer the newest patch of the lowest supported major"
)
assert_equal(0, version_probes, "Valid release files should eliminate Java subprocesses")
assert_equal({
  { name = "JavaSE-1.8", path = java8 },
  { name = "JavaSE-17", path = java17 },
  { name = "JavaSE-21", path = java21_new, default = true },
  { name = "JavaSE-25", path = java25 },
}, metadata_runtimes, "Metadata parsing should preserve project runtimes and select exactly one launcher default")

local first_release_reads = release_reads
metadata_runtimes[1].path = "/mutated"
local cached_runtimes, cached_launcher = java_runtime.discover(metadata_env, metadata_opts)
assert_equal(first_release_reads, release_reads, "Repeated discovery should reuse metadata")
assert_equal(java21_new, cached_launcher, "Repeated discovery should preserve the launcher")
assert_equal(java8, cached_runtimes[1].path, "Callers must not mutate cached runtime tables")

local override_runtimes, override_launcher = java_runtime.discover({
  JAVA_HOME = java17,
  NVIM_JAVA_HOME = java21_old,
}, metadata_opts)
assert_equal(java21_old, override_launcher, "Changed launcher overrides must invalidate discovery")
assert_equal(java21_old, override_runtimes[3].path, "The selected launcher should be represented in its runtime entry")
assert_equal(java17, override_runtimes[2].path, "Changing the launcher must preserve the project Java home")

local current = temp_dir .. "/current"
assert(vim.uv.fs_symlink(java21_new, current), "The test JDK alias should be created")
release_reads = 0
local alias_runtimes, alias_launcher = java_runtime.discover({ JAVA_HOME = current }, {
  sdkman_homes = { java21_old, java21_new, current },
})
assert_equal(java21_new, alias_launcher, "A JDK also referenced by JAVA_HOME should retain SDKMAN selection priority")
assert_equal(2, release_reads, "Aliases of a JDK should be inspected only once")
assert_equal(1, #alias_runtimes, "JDK aliases should not create duplicate runtimes")
assert(vim.uv.fs_unlink(current))
assert(vim.uv.fs_symlink(java25, current))
local _, changed_alias_launcher = java_runtime.discover({ NVIM_JAVA_HOME = current }, {
  sdkman_homes = { java21_new, current },
})
assert_equal(java25, changed_alias_launcher, "An updated JDK symlink must select its new target")

local missing_release = make_jdk("jdk-fallback")
vim.system = function(command, options)
  version_probes = version_probes + 1
  assert_equal(
    { missing_release .. "/bin/java", "-version" },
    command,
    "Only metadata-less JDKs should need a subprocess"
  )
  assert(options.timeout and options.timeout > 0, "Fallback probing must have a timeout")
  return {
    wait = function()
      return { code = 0, stdout = "", stderr = 'openjdk version "21.0.9" 2025-10-21' }
    end,
  }
end
local _, fallback_metadata_launcher = java_runtime.discover({ JAVA_HOME = missing_release }, { sdkman_homes = {} })
assert_equal(missing_release, fallback_metadata_launcher, "Missing metadata should fall back to Java version output")
local probes_after_fallback = version_probes
java_runtime.discover({ JAVA_HOME = missing_release }, { sdkman_homes = {} })
assert_equal(probes_after_fallback, version_probes, "Fallback results should also be cached")

vim.fn.writefile({ 'JAVA_VERSION="17.0.15"' }, missing_release .. "/release")
local changed_metadata_runtimes, changed_metadata_launcher = java_runtime.discover(
  { JAVA_HOME = missing_release },
  { sdkman_homes = {} }
)
assert_equal(nil, changed_metadata_launcher, "New release metadata must invalidate a cached version")
assert_equal("JavaSE-17", changed_metadata_runtimes[1].name, "Updated metadata must determine the project runtime")

local retry_home = make_jdk("jdk-retry", "unknown")
local retry_probes = 0
vim.system = function()
  retry_probes = retry_probes + 1
  if retry_probes == 2 then
    error("temporary spawn failure")
  end
  return {
    wait = function()
      return {
        code = retry_probes == 1 and 124 or 0,
        stdout = "",
        stderr = 'openjdk version "21.0.10"',
      }
    end,
  }
end
local retry_env, retry_opts = { JAVA_HOME = retry_home }, { sdkman_homes = {} }
local _, timed_out_launcher = java_runtime.discover(retry_env, retry_opts)
assert_equal(nil, timed_out_launcher, "A timed-out version probe must not select a launcher")
local _, failed_launcher = java_runtime.discover(retry_env, retry_opts)
assert_equal(nil, failed_launcher, "A failed subprocess must be ignored without throwing")
local _, recovered_launcher = java_runtime.discover(retry_env, retry_opts)
assert_equal(retry_home, recovered_launcher, "Failed discovery must be retried even when metadata is unchanged")
java_runtime.discover(retry_env, retry_opts)
assert_equal(3, retry_probes, "Successful retry results should be cached")

vim.system = original_system
vim.fn.readfile = original_readfile
vim.fn.delete(temp_dir, "rf")

print("java-runtime-tests: ok")
