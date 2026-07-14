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
local mason_root = temp_dir .. "/mason"
vim.fn.mkdir(mason_root .. "/packages/java-debug-adapter/extension/server", "p")
vim.fn.mkdir(mason_root .. "/packages/java-test/extension/server", "p")
vim.fn.mkdir(mason_root .. "/packages/jdtls/plugins", "p")
vim.fn.writefile({}, mason_root .. "/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-1.jar")
vim.fn.writefile({}, mason_root .. "/packages/java-test/extension/server/com.microsoft.java.test.plugin.jar")
vim.fn.writefile({}, mason_root .. "/packages/java-test/extension/server/com.microsoft.java.test.runner.jar")
vim.fn.writefile({}, mason_root .. "/packages/java-test/extension/server/jacocoagent.jar")
vim.fn.writefile({}, mason_root .. "/packages/jdtls/plugins/org.eclipse.m2e.jdt_1.jar")

local java_debug = require("custom.java_debug")

assert_equal({
  mason_root .. "/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-1.jar",
}, java_debug.bundles(mason_root), "application debugging should not load incompatible Java Test bundles")

local fingerprint = java_debug.toolchain_fingerprint(mason_root)
vim.fn.writefile({}, mason_root .. "/packages/jdtls/plugins/org.eclipse.m2e.jdt_2.jar")
assert(fingerprint ~= java_debug.toolchain_fingerprint(mason_root),
  "jdtls workspace fingerprint should change with the Maven integration plugin")

local launch = java_debug.launch_config({
  name = "OrderApplication",
  metadata = {
    project_root = "/repo",
    project_name = "order-service",
    main_class = "com.example.OrderApplication",
  },
})
assert_equal("java", launch.type, "service launch should use the Java adapter")
assert_equal("launch", launch.request, "service launch should launch a new JVM")
assert_equal("com.example.OrderApplication", launch.mainClass, "service launch should target only its selected main class")
assert_equal("order-service", launch.projectName, "service launch should target the selected Maven module")
assert_equal("/repo", launch.cwd, "jdtls root should be used to select the correct language-server client")

local enriched, enrich_err
local command_order = {}
java_debug.enrich_launch_config({
  name = "OrderApplication",
  metadata = {
    project_root = "/repo",
    project_name = "order-service",
    main_class = "com.example.OrderApplication",
  },
}, 42, function(config, err)
  enriched, enrich_err = config, err
end, function(params, callback, bufnr)
  assert_equal(42, bufnr, "every enrichment request should use the main-class source buffer")
  table.insert(command_order, params.command)
  if params.command == "vscode.java.resolveJavaExecutable" then
    callback(nil, "/jdk/bin/java")
  elseif params.command == "vscode.java.resolveClasspath" then
    callback(nil, { { "/modules" }, { "/classes", "/dependency.jar" } })
  elseif params.command == "vscode.java.checkProjectSettings" then
    callback(nil, true)
  end
end)
assert_equal(nil, enrich_err, "successful enrichment should not return an error")
assert_equal({
  "vscode.java.resolveJavaExecutable",
  "vscode.java.resolveClasspath",
  "vscode.java.checkProjectSettings",
}, command_order, "only the selected service should be enriched in deterministic order")
assert_equal("/jdk/bin/java", enriched.javaExec, "enrichment should resolve the Java executable")
assert_equal({ "/classes", "/dependency.jar" }, vim.fn.sort(enriched.classPaths),
  "enrichment should resolve the selected service classpath")
assert_equal("--enable-preview", enriched.vmArgs, "preview-enabled projects should retain their launch flag")

local adapter_port, adapter_err
java_debug.start_debug_adapter(42, function(port, err)
  adapter_port, adapter_err = port, err
end, function(params, callback, bufnr)
  assert_equal("vscode.java.startDebugSession", params.command, "adapter startup should use the jdtls debug command")
  assert_equal(42, bufnr, "adapter startup should use the selected service buffer")
  callback(nil, 5005)
end)
assert_equal(nil, adapter_err, "adapter startup should not return an error")
assert_equal(5005, adapter_port, "adapter startup should return the jdtls server port")

local project_root = temp_dir .. "/project"
vim.fn.mkdir(project_root .. "/.nvim", "p")
vim.fn.writefile({ vim.json.encode({
  defaults = {
    vmArgs = "-Xms256m",
    env = { SHARED = "default", DEFAULT_ONLY = "yes" },
  },
  services = {
    ["com.example.OrderApplication"] = {
      vmArgs = "-Xmx2g",
      args = "--server.port=8082",
      env = { SHARED = "service" },
    },
  },
}) }, project_root .. "/.nvim/java-debug.json")

local resolved, config_err = java_debug.resolve_config({
  mainClass = "com.example.OrderApplication",
  vmArgs = "--enable-preview",
  env = { GENERATED = "yes" },
}, project_root, "com.example.OrderApplication", "dev")
assert_equal(nil, config_err, "valid project config should not return an error")
assert_equal("--enable-preview -Xms256m -Xmx2g -Dspring.profiles.active=dev", resolved.vmArgs,
  "vmArgs and selected profile should be appended in precedence order")
assert_equal("--server.port=8082", resolved.args, "service arguments should override generated values")
assert_equal({
  GENERATED = "yes",
  SHARED = "service",
  DEFAULT_ONLY = "yes",
}, resolved.env, "environment variables should be deep merged")

local configs = {
  { mainClass = "com.example.OrderApplication", projectName = "shared" },
  { mainClass = "com.example.OrderApplication", projectName = "order-service" },
  { mainClass = "com.example.UserApplication", projectName = "user-service" },
}
local match, match_err = java_debug.match_config(configs, "com.example.OrderApplication", "/repo/order", "order-service")
assert_equal(nil, match_err, "module name should disambiguate duplicate main classes")
assert_equal("order-service", match.projectName, "matching should prefer the module project")

local missing, missing_err = java_debug.match_config(configs, "com.example.MissingApplication", "/repo/missing")
assert_equal(nil, missing, "missing main class should not return a config")
assert(missing_err and missing_err:find("MissingApplication", 1, true), "missing main class should return an actionable error")

local original_buf = vim.api.nvim_get_current_buf()
local output_buf = vim.api.nvim_create_buf(false, true)
local dap_buf = vim.api.nvim_create_buf(false, true)
local output_win = vim.api.nvim_get_current_win()
vim.api.nvim_win_set_buf(output_win, output_buf)
local task = { strategy = { bufnr = output_buf } }
local win_count = #vim.api.nvim_list_wins()
local adopted_win = java_debug.adopt_output_buffer(task, dap_buf)
assert_equal(dap_buf, task.strategy.bufnr, "DAP terminal should become the task output buffer")
assert_equal(dap_buf, vim.api.nvim_win_get_buf(output_win), "visible task output should be replaced in place")
assert_equal(output_win, adopted_win, "the existing output window should be returned to nvim-dap")
assert_equal(win_count, #vim.api.nvim_list_wins(), "output adoption must not create a new window")

local hidden_output = vim.api.nvim_create_buf(false, true)
local hidden_dap = vim.api.nvim_create_buf(false, true)
local hidden_task = { strategy = { bufnr = hidden_output } }
vim.api.nvim_win_set_buf(output_win, original_buf)
local hidden_win = java_debug.adopt_output_buffer(hidden_task, hidden_dap)
assert_equal(hidden_dap, hidden_task.strategy.bufnr, "hidden DAP output should still be adopted by the task")
assert_equal(nil, hidden_win, "no output window should be returned when the task output is hidden")
assert_equal(win_count, #vim.api.nvim_list_wins(), "hidden output adoption must not create a window")
vim.api.nvim_buf_set_lines(hidden_dap, 0, -1, false, { "debug line 1", "debug line 2" })
local archived_buf = java_debug.archive_output_buffer(hidden_task, hidden_dap)
assert(archived_buf and vim.api.nvim_buf_is_valid(archived_buf), "completed debug output should be archived")
assert_equal({ "debug line 1", "debug line 2" }, vim.api.nvim_buf_get_lines(archived_buf, 0, -1, false),
  "archived output should preserve terminal lines")
assert_equal(archived_buf, hidden_task.strategy.bufnr, "the archive should remain available as task output")
assert_equal(false, vim.api.nvim_buf_is_valid(hidden_dap), "the DAP terminal must be deleted to prevent cross-service reuse")

local stale_terminal = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_name(stale_terminal, "[dap-terminal] stale-java-service")
vim.b[stale_terminal]["dap-type"] = "java"
local stale_other_terminal = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_name(stale_other_terminal, "[dap-terminal] stale-node-service")
vim.b[stale_other_terminal]["dap-type"] = "node"
java_debug.cleanup_stale_terminals()
assert_equal(false, vim.api.nvim_buf_is_valid(stale_terminal),
  "stale Java terminals should be invalidated so nvim-dap cannot bypass output adoption")
assert_equal(false, vim.api.nvim_buf_is_valid(stale_other_terminal),
  "the cross-adapter terminal pool must be cleared before output adoption")

vim.fn.delete(temp_dir, "rf")
print("java-debug-tests: ok")
