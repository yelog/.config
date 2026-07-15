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

local spawned = {}
local runtime = require("services.runtime").new({
  output_limit = 20,
  spawn = function(command, opts, on_exit)
    local process = {
      killed = {},
      kill = function(self, signal)
        table.insert(self.killed, signal)
      end,
    }
    table.insert(spawned, { command = command, opts = opts, on_exit = on_exit, process = process })
    return process
  end,
})

local definition = {
  key = "springboot::orders",
  name = "OrdersApplication",
  service_type = "springboot",
  cmd = { "run-orders" },
  cwd = "/project",
  metadata = { project_root = "/project", ready = false },
  restart = { auto = true, delay = 60, max_attempts = 2 },
  prepare = function(_, profile)
    return { "run-orders", profile or "default" }
  end,
  parse_line = function(metadata, line)
    if line == "ready" and not metadata.ready then
      metadata.ready = true
      metadata.url = "http://localhost:8080"
      return true
    end
    return false
  end,
}

local service = runtime:register(definition)
local events = {}
service:subscribe(function(event) table.insert(events, event.type) end)

assert(runtime:start(service.key, { profile = "dev" }), "starting a pending service should succeed")
assert_equal("RUNNING", service.status, "successful spawn should mark a service running")
assert_equal({ "run-orders", "dev" }, spawned[1].command, "start should call provider preparation")
assert_equal("dev", service.metadata.profile, "selected profile should be retained on the service record")

spawned[1].opts.on_output("stdout", nil, "\27[32mready\27[0m\n")
assert(vim.wait(500, function()
  return service.metadata.ready and vim.api.nvim_buf_get_lines(service.output.bufnr, -2, -1, false)[1] == "ready"
end), "output should be parsed and rendered")
assert_equal("http://localhost:8080", service.metadata.url, "parsers should update service metadata")

assert(runtime:stop(service.key), "stopping a live service should succeed")
assert_equal("STOPPING", service.status, "manual stop should expose the stopping state")
assert_equal({ 15 }, spawned[1].process.killed, "manual stop should send TERM first")
spawned[1].on_exit({ code = 1, signal = 15 })
assert_equal("STOPPED", service.status, "manual stop should never schedule an auto-restart")

assert(runtime:start(service.key, { profile = "dev" }), "stopped service should start again")
local second = spawned[2]
second.on_exit({ code = 1, signal = 0 })
assert_equal("RESTART_PENDING", service.status, "failed services should schedule configured auto-restart")
assert_equal(1, service.restart_count, "failure should increment the restart count")

assert(runtime:stop(service.key), "stopping a pending restart should succeed")
assert_equal("STOPPED", service.status, "manual stop should cancel a pending restart")

assert(runtime:start(service.key, { profile = "prod" }), "service should start after restart cancellation")
local third = spawned[3]
assert(runtime:restart(service.key, { profile = "qa" }), "restart should stop an active process before relaunching")
assert_equal("STOPPING", service.status, "restart should wait for the active process exit")
third.on_exit({ code = 0, signal = 15 })
assert(vim.wait(500, function() return #spawned == 4 end), "restart should launch a new generation after exit")
assert_equal({ "run-orders", "qa" }, spawned[4].command, "restart should use the requested profile")

local current_status = service.status
second.on_exit({ code = 1, signal = 0 })
assert_equal(current_status, service.status, "stale exit callbacks must not overwrite a newer generation")

local normal_output = runtime:get_output_bufnr(service.key)
local terminal_output = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(terminal_output, 0, -1, false, { "debug output" })
assert_equal(terminal_output, runtime:replace_output(service.key, terminal_output, { terminal = true }),
  "runtime should bind an external DAP terminal to the service")
assert_equal(terminal_output, runtime:get_output_bufnr(service.key), "external terminal should become active output")
assert(runtime:archive_terminal_output(service.key, terminal_output), "terminal output should archive into normal service output")
assert_equal(normal_output, runtime:get_output_bufnr(service.key), "archiving should restore the normal output buffer")
assert(vim.wait(500, function()
  return vim.api.nvim_buf_get_lines(normal_output, -2, -1, false)[1] == "debug output"
end), "terminal archive should retain visible text")

local failed_runtime = require("services.runtime").new({
  spawn = function()
    error("missing executable")
  end,
})
local failed = failed_runtime:register(vim.tbl_extend("force", {}, definition, { key = "service::failed" }))
assert_equal(false, failed_runtime:start(failed.key), "spawn errors should fail the start operation")
assert_equal("FAILED", failed.status, "spawn errors should mark the service failed")

runtime:dispose(service.key)
failed_runtime:dispose(failed.key)
if vim.api.nvim_buf_is_valid(terminal_output) then vim.api.nvim_buf_delete(terminal_output, { force = true }) end

local real_runtime = require("services.runtime").new({ output_limit = 10 })
local real_service = real_runtime:register({
  key = "service::smoke",
  name = "smoke",
  service_type = "service",
  cmd = { "sh", "-c", "printf '\\033[32mok\\033[0m\\n'" },
  metadata = { project_root = "/smoke" },
})
assert(real_runtime:start(real_service.key), "the default vim.system adapter should start a real process")
assert(vim.wait(1000, function()
  return real_service.status == "STOPPED"
    and vim.api.nvim_buf_get_lines(real_service.output.bufnr, -2, -1, false)[1] == "ok"
end), "the default adapter should render and finish real process output")
assert(#vim.api.nvim_buf_get_extmarks(real_service.output.bufnr, real_service.output.namespace, 0, -1, {}) > 0,
  "ANSI output from a real process should retain a highlight span")
real_runtime:dispose(real_service.key)

local stop_runtime = require("services.runtime").new({ kill_timeout_ms = 500 })
local stop_service = stop_runtime:register({
  key = "service::stop-smoke",
  name = "stop-smoke",
  service_type = "service",
  cmd = { "sleep", "30" },
  metadata = { project_root = "/smoke" },
})
assert(stop_runtime:start(stop_service.key), "the default adapter should start a long-running process")
assert_equal("RUNNING", stop_service.status, "long-running process should be running before stop")
assert(stop_runtime:stop(stop_service.key), "the default adapter should stop a live process")
assert(vim.wait(1000, function() return stop_service.status == "STOPPED" end),
  "TERM should transition a real process to stopped")
stop_runtime:dispose(stop_service.key)

print("services-runtime-tests: ok")
