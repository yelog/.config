local test_file = debug.getinfo(1, "S").source:gsub("^@", "")
local config_root = vim.fs.dirname(vim.fs.dirname(test_file))
package.path = config_root .. "/lua/?.lua;" .. config_root .. "/lua/?/init.lua;" .. package.path

local function assert_equal(expected, actual, message)
  assert(
    vim.deep_equal(expected, actual),
    message .. "\nexpected: " .. vim.inspect(expected) .. "\nactual: " .. vim.inspect(actual)
  )
end

local configs = {}
local launcher = "/jdk25"
local launcher_error
local original_java_home = vim.env.JAVA_HOME
local project_runtimes = {
  { name = "JavaSE-17", path = "/jdk17", default = true },
  { name = "JavaSE-21", path = "/jdk21" },
  { name = "JavaSE-25", path = "/jdk25" },
}
local bundles = { "/spring.jar", "/debug.jar" }
package.loaded["jdtls"] = {
  extendedClientCapabilities = { classFileContentsSupport = true },
  start_or_attach = function(config, options, start_options)
    table.insert(configs, vim.deepcopy(config))
    assert_equal("auto", options.dap.hotcodereplace, "Hot code replacement should remain enabled")
    assert_equal(vim.api.nvim_get_current_buf(), start_options.bufnr, "Java should attach to the requested buffer")
  end,
}
package.loaded["nvim-navic"] = {}
package.loaded["custom.mybatis_diagnostics"] = { setup = function() end }
package.loaded["blink.cmp"] = {
  get_lsp_capabilities = function()
    return {}
  end,
}
package.loaded["custom.java_runtime"] = {
  discover = function()
    return vim.deepcopy(project_runtimes), launcher, launcher_error
  end,
}
package.loaded["spring_boot"] = {
  java_extensions = function()
    return { bundles[1] }
  end,
}
package.loaded["custom.java_debug"] = {
  bundles = function()
    return { bundles[2] }
  end,
  toolchain_fingerprint = function(_, extensions)
    assert_equal(bundles, extensions, "Spring and application debugging bundles should be retained")
    return "toolchain"
  end,
}

local spring_options = dofile(config_root .. "/lua/plugins/lsp/spring_boot.lua")[1].opts()
assert_equal(launcher .. "/bin/java", spring_options.java_cmd, "Spring should use the validated language-server JDK")
assert_equal(10000, spring_options.server.exit_timeout, "Spring should have time to finish graceful shutdown")
assert_equal(true, spring_options.autocmd, "Spring should attach only with a compatible language-server JDK")

local temp_dir = vim.fn.tempname()
local first_root = temp_dir .. "/first/project"
local second_root = temp_dir .. "/second/project"
for _, root in ipairs({ first_root, second_root }) do
  vim.fn.mkdir(root .. "/.git", "p")
  vim.fn.mkdir(root .. "/module/src", "p")
  vim.fn.writefile({ "<project/>" }, root .. "/module/pom.xml")
  vim.fn.writefile({ "class Main {}" }, root .. "/module/src/Main.java")
end
first_root = vim.uv.fs_realpath(first_root)
second_root = vim.uv.fs_realpath(second_root)

vim.cmd.edit(vim.fn.fnameescape(first_root .. "/module/src/Main.java"))
vim.bo.filetype = "java"
dofile(config_root .. "/lua/plugins/lsp/jdtls.lua")[1].config()
assert_equal(1, #configs, "An already-open Java buffer should start JDTLS")

local function command_value(config, argument)
  for index, value in ipairs(config.cmd) do
    if value == argument then
      return config.cmd[index + 1]
    end
  end
end

local first_config = configs[1]
local workspace_name = "project-" .. vim.fn.sha256(first_root):sub(1, 12) .. "-toolchain"
local cache = vim.fn.stdpath("cache") .. "/jdtls"
assert_equal(
  cache .. "/workspace/" .. workspace_name,
  command_value(first_config, "-data"),
  "Existing workspace paths should stay compatible"
)
assert_equal(
  cache .. "/config/" .. workspace_name,
  command_value(first_config, "-configuration"),
  "OSGi state should be isolated from the installation and other project configurations"
)
assert_equal(10000, first_config.exit_timeout, "JDTLS should have time to finish graceful shutdown")
assert_equal(launcher, first_config.cmd_env.JAVA_HOME, "The launcher must receive the validated Java home")
assert_equal(
  project_runtimes,
  first_config.settings.java.configuration.runtimes,
  "JDTLS must retain the project's Java 17 default"
)
assert_equal(
  first_config.settings,
  first_config.init_options.settings,
  "Project runtimes must be available before import and extension loading"
)
assert_equal(original_java_home, vim.env.JAVA_HOME, "Language-server setup must not change Maven's JAVA_HOME")
assert_equal(first_root, first_config.root_dir, "Multi-module files should share the repository root")
assert(
  vim.tbl_contains(first_config.cmd, "--jvm-arg=-DDetectVMInstallationsJob.disabled=true"),
  "JDTLS should reuse explicit runtimes instead of discovering JDKs again"
)
assert(
  vim.tbl_contains(first_config.cmd, "--jvm-arg=-Dm2e.project.cache.size=128"),
  "The Maven model cache should accommodate the existing multi-module projects"
)
assert_equal(true, first_config.settings.java.autobuild.enabled, "Automatic builds should remain enabled")
assert_equal(
  true,
  first_config.settings.java.maven.downloadSources,
  "Dependency source navigation should remain enabled"
)
assert_equal(bundles, first_config.init_options.bundles, "Spring and application debugging should remain available")

vim.api.nvim_exec_autocmds("FileType", { pattern = "java" })
assert_equal(first_config.cmd, configs[2].cmd, "Repeated Java buffers should use the same persistent directories")

vim.cmd.edit(vim.fn.fnameescape(second_root .. "/module/src/Main.java"))
vim.bo.filetype = "java"
if #configs == 2 then
  vim.api.nvim_exec_autocmds("FileType", { pattern = "java" })
end
local second_config = configs[#configs]
assert(
  command_value(first_config, "-data") ~= command_value(second_config, "-data"),
  "Same-named repositories at different paths must have separate workspaces"
)
assert(
  command_value(first_config, "-configuration") ~= command_value(second_config, "-configuration"),
  "Same-named repositories at different paths must have separate OSGi registries"
)

local original_notify = vim.notify
local notifications = {}
vim.notify = function(message, level)
  notifications[#notifications + 1] = { message = message, level = level }
end
launcher = nil
launcher_error = "NVIM_JAVA_HOME must point to JDK 25 or newer: /jdk21"
local invalid_spring_options = dofile(config_root .. "/lua/plugins/lsp/spring_boot.lua")[1].opts()
assert_equal(false, invalid_spring_options.autocmd, "Spring must not fall back to the project's incompatible JVM")
assert_equal(nil, invalid_spring_options.java_cmd, "An incompatible override must not be passed to Spring")
local started_count = #configs
dofile(config_root .. "/lua/plugins/lsp/jdtls.lua")[1].config()
vim.api.nvim_exec_autocmds("FileType", { pattern = "java" })
assert_equal(started_count, #configs, "An incompatible override must prevent JDTLS from launching")
assert_equal(1, #notifications, "Repeated Java and Spring setup should report the same JVM error only once")
assert_equal(launcher_error, notifications[1].message, "The startup error must explain which override to fix")
assert_equal(
  vim.log.levels.ERROR,
  notifications[1].level,
  "An unusable language-server JVM must be reported as an error"
)
vim.notify = original_notify

vim.fn.delete(temp_dir, "rf")
print("jdtls-startup-tests: ok")
