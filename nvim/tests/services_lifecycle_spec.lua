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

local lifecycle = require("services.lifecycle")

local completed_calls = {}
local completed_runtime = {
  begin_shutdown = function()
    table.insert(completed_calls, "runtime.begin")
    return true
  end,
  is_shutdown_complete = function()
    table.insert(completed_calls, "runtime.complete")
    return true
  end,
  force_shutdown = function()
    table.insert(completed_calls, "runtime.force")
  end,
}
local completed_debug = {
  begin_shutdown = function()
    table.insert(completed_calls, "debug.begin")
    return true
  end,
  is_shutdown_complete = function()
    table.insert(completed_calls, "debug.complete")
    return true
  end,
  force_shutdown = function()
    table.insert(completed_calls, "debug.force")
  end,
}
assert(lifecycle.shutdown(completed_runtime, {
  java_debug = completed_debug,
  wait = function()
    error("completed shutdown should not wait")
  end,
}), "a completed lifecycle shutdown should succeed")
assert_equal({ "runtime.begin", "debug.begin", "runtime.complete", "debug.complete", "runtime.complete", "debug.complete" },
  completed_calls, "completed shutdown should begin both paths without force escalation")

local forced_calls = {}
local forced_runtime = {
  begin_shutdown = function()
    table.insert(forced_calls, "runtime.begin")
    return true
  end,
  is_shutdown_complete = function()
    table.insert(forced_calls, "runtime.complete")
    return false
  end,
  force_shutdown = function()
    table.insert(forced_calls, "runtime.force")
  end,
}
local forced_debug = {
  begin_shutdown = function()
    table.insert(forced_calls, "debug.begin")
    return true
  end,
  is_shutdown_complete = function()
    table.insert(forced_calls, "debug.complete")
    return false
  end,
  force_shutdown = function()
    table.insert(forced_calls, "debug.force")
  end,
}
local waited_ms
assert_equal(false, lifecycle.shutdown(forced_runtime, {
  java_debug = forced_debug,
  grace_ms = 123,
  wait = function(timeout, predicate)
    waited_ms = timeout
    assert_equal(false, predicate(), "the lifecycle predicate should wait for both shutdown paths")
    return false
  end,
}), "an incomplete lifecycle shutdown should report pending work after escalation")
assert_equal(123, waited_ms, "the lifecycle should use the configured shared grace period")
assert_equal({
  "runtime.begin", "debug.begin", "runtime.complete", "debug.complete", "runtime.complete", "debug.complete",
  "runtime.force", "debug.force", "runtime.complete", "debug.complete",
}, forced_calls, "the lifecycle should force both incomplete shutdown paths after waiting")

lifecycle.setup(completed_runtime, { java_debug = completed_debug })
lifecycle.setup(completed_runtime, { java_debug = completed_debug })
local group = vim.api.nvim_create_augroup("ServicesLifecycle", { clear = false })
assert_equal(1, #vim.api.nvim_get_autocmds({ group = group, event = "VimLeavePre" }),
  "lifecycle setup should register one VimLeavePre hook")

if vim.uv.os_uname().sysname ~= "Windows_NT" and vim.fn.executable("python3") == 1 then
  local runtime = require("services.runtime").new()
  local service = runtime:register({
    key = "service::lifecycle-tree",
    name = "lifecycle-tree",
    service_type = "service",
    cmd = {
      "python3",
      "-c",
      "import os, signal, sys, time; child = os.fork(); "
        .. "(os.close(1), os.close(2), signal.signal(signal.SIGTERM, signal.SIG_IGN)) if child == 0 "
        .. "else signal.signal(signal.SIGTERM, lambda *_: sys.exit(0)); time.sleep(30)",
    },
    metadata = { project_root = "/smoke" },
  })
  assert(runtime:start(service.key), "lifecycle smoke coverage needs a running service")
  local process_pid = assert(service.process and service.process.pid, "lifecycle service should expose its pid")
  local lifecycle_ok, lifecycle_err = pcall(function()
    local child_pid
    assert(vim.wait(1000, function()
      local result = vim.system({ "pgrep", "-P", tostring(process_pid) }, { text = true }):wait()
      child_pid = tonumber((result.stdout or ""):match("%d+"))
      return child_pid ~= nil
    end), "lifecycle smoke service should have a child process")
    lifecycle.setup(runtime, {
      grace_ms = 50,
      java_debug = { is_shutdown_complete = function() return true end },
    })
    vim.api.nvim_exec_autocmds("VimLeavePre", {})
    assert(vim.wait(1000, function() return vim.uv.kill(child_pid, 0) ~= 0 end),
      "VimLeavePre should force-stop descendants that ignore TERM")
  end)
  pcall(vim.uv.kill, -process_pid, 9)
  if not lifecycle_ok then error(lifecycle_err) end
  runtime:dispose(service.key)
end

print("services-lifecycle-tests: ok")
