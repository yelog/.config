local output = require("services.output")

local M = {}

local Runtime = {}
Runtime.__index = Runtime

local Service = {}
Service.__index = Service

local active_statuses = {
  STARTING = true,
  RUNNING = true,
  STOPPING = true,
  DEBUGGING = true,
}

local function close_timer(timer)
  if not timer then return end
  pcall(timer.stop, timer)
  pcall(timer.close, timer)
end

local function kill_process(process, signal)
  if process and type(process.kill) == "function" then pcall(process.kill, process, signal) end
end

local function supports_process_groups()
  local uname = vim.uv.os_uname()
  return uname and uname.sysname ~= "Windows_NT"
end

local function signal_process_group(group_id, signal)
  if not group_id then return false end
  local ok, result = pcall(vim.uv.kill, -group_id, signal)
  return ok and result == 0
end

local function default_spawn(command, opts, on_exit)
  local grouped = supports_process_groups()
  local system = vim.system(command, {
    cwd = opts.cwd,
    env = opts.env,
    text = true,
    detach = grouped,
    stdout = function(err, data)
      vim.schedule(function() opts.on_output("stdout", err, data) end)
    end,
    stderr = function(err, data)
      vim.schedule(function() opts.on_output("stderr", err, data) end)
    end,
  }, function(result)
    vim.schedule(function() on_exit(result) end)
  end)
  if not grouped then return system end

  return {
    pid = system.pid,
    group_id = system.pid,
    system = system,
    kill = function(_, signal)
      if signal_process_group(system.pid, signal) then return true end
      return pcall(system.kill, system, signal)
    end,
    is_closing = function() return system:is_closing() end,
  }
end

function Service:subscribe(callback)
  if type(callback) ~= "function" then return function() end end
  table.insert(self.subscribers, callback)
  return function()
    for index, subscriber in ipairs(self.subscribers) do
      if subscriber == callback then
        table.remove(self.subscribers, index)
        break
      end
    end
  end
end

function Runtime:_emit(service, event_type, detail)
  local event = { type = event_type, service = service, detail = detail }
  for _, callback in ipairs(service.subscribers) do
    pcall(callback, event)
  end
  for _, callback in ipairs(self.subscribers) do
    pcall(callback, event)
  end
end

function Runtime:_ensure_output(service)
  if service.output and vim.api.nvim_buf_is_valid(service.output.bufnr) then return service.output end

  service.output = output.new({
    name = service.name,
    limit = self.output_limit,
    on_line = function(line, stream)
      if stream ~= "archive" then self:_parse_line(service, line) end
    end,
  })
  if not service.output_bufnr or not vim.api.nvim_buf_is_valid(service.output_bufnr) then
    service.output_bufnr = service.output.bufnr
    service.terminal_output = false
  end
  return service.output
end

function Runtime:_parse_line(service, line)
  local parser = service.definition.parse_line
  if type(parser) ~= "function" then return end
  local ok, changed = pcall(parser, service.metadata, line)
  if not ok then
    service.parser_error = changed
    self:_emit(service, "parser_error", changed)
  elseif changed then
    self:_emit(service, "updated")
  end
end

function Runtime:_reset_metadata(service, profile)
  service.metadata.ready = false
  service.metadata.port = nil
  service.metadata.protocol = nil
  service.metadata.context_path = nil
  service.metadata.url = nil
  service.metadata.profile = profile
  service.metadata.restart_count = service.restart_count
  service.metadata.started_at = os.time()
end

function Runtime:_stop_health_check(service)
  close_timer(service.health_timer)
  service.health_timer = nil
end

function Runtime:_start_health_check(service, generation)
  local health_check = service.definition.health_check
  if not health_check then return end

  local interval = math.max(1, service.definition.health_interval or 10) * 1000
  local timer = vim.uv.new_timer()
  service.health_timer = timer
  timer:start(interval, interval, vim.schedule_wrap(function()
    if service.generation ~= generation or not active_statuses[service.status] then
      self:_stop_health_check(service)
      return
    end
    local command = type(health_check) == "table" and health_check or { "sh", "-c", health_check }
    local ok, err = pcall(vim.system, command, { cwd = service.cwd, text = true }, function(result)
      vim.schedule(function()
        if service.generation ~= generation or result.code == 0 then return end
        self:_emit(service, "health_failed", result)
      end)
    end)
    if not ok then self:_emit(service, "health_failed", err) end
  end))
end

function Runtime:_cancel_restart(service)
  close_timer(service.restart_timer)
  service.restart_timer = nil
end

function Runtime:_schedule_restart(service, generation)
  if self.shutting_down then return false end
  local policy = service.definition.restart or {}
  if not policy.auto then return false end

  service.restart_count = service.restart_count + 1
  service.metadata.restart_count = service.restart_count
  local max_attempts = policy.max_attempts or 3
  if max_attempts > 0 and service.restart_count > max_attempts then
    self:_emit(service, "restart_exhausted")
    return false
  end

  local timer = vim.uv.new_timer()
  service.restart_timer = timer
  service.status = "RESTART_PENDING"
  self:_emit(service, "restart_pending")
  timer:start(math.max(0, policy.delay or 3) * 1000, 0, vim.schedule_wrap(function()
    if service.restart_timer == timer then service.restart_timer = nil end
    close_timer(timer)
    if service.generation ~= generation or service.status ~= "RESTART_PENDING" then return end
    self:start(service.key, { profile = service.metadata.profile, auto_restart = true })
  end))
  return true
end

function Runtime:_schedule_escalation(service, process, generation)
  local timer = vim.uv.new_timer()
  service.kill_timer = timer
  timer:start(self.kill_timeout_ms, 0, vim.schedule_wrap(function()
    if service.kill_timer == timer then service.kill_timer = nil end
    close_timer(timer)
    if service.generation == generation and service.process == process and service.status == "STOPPING" then
      kill_process(process, 9)
    end
  end))
end

function Runtime:_on_output(service, generation, stream, err, data)
  if service.generation ~= generation or service.disposed then return end
  local renderer = self:_ensure_output(service)
  if err and err ~= "" then renderer:push(stream, "[output error] " .. tostring(err) .. "\n") end
  if data and data ~= "" then renderer:push(stream, data) end
end

function Runtime:_on_exit(service, generation, result)
  if service.generation ~= generation or service.disposed then return end

  service.process = nil
  if not self.shutting_down then service.process_group_id = nil end
  close_timer(service.kill_timer)
  service.kill_timer = nil
  self:_stop_health_check(service)
  if service.output then service.output:flush() end

  local should_restart = service.restart_after_stop
  local restart_profile = service.restart_profile
  local manually_stopped = service.stop_requested
  service.restart_after_stop = false
  service.restart_profile = nil
  service.stop_requested = false

  if should_restart then
    service.status = "STOPPED"
    self:_emit(service, "stopped")
    self:start(service.key, { profile = restart_profile, auto_restart = false })
    return
  end
  if manually_stopped then
    service.status = "STOPPED"
    self:_emit(service, "stopped")
    return
  end
  if self.shutting_down then
    service.status = "STOPPED"
    self:_emit(service, "stopped", result)
    return
  end

  local code = tonumber(result and result.code) or 1
  if code == 0 then
    service.status = "STOPPED"
    self:_emit(service, "stopped", result)
    return
  end

  service.status = "FAILED"
  service.last_exit = result
  self:_emit(service, "failed", result)
  self:_schedule_restart(service, generation)
end

function Runtime:register(definition)
  assert(type(definition) == "table" and type(definition.key) == "string", "service definition requires a key")
  local service = self.services[definition.key]
  if service then
    service.definition = definition
    service.name = definition.name
    service.service_type = definition.service_type
    service.cwd = definition.cwd
    service.env = vim.deepcopy(definition.env)
    return service
  end

  service = setmetatable({
    key = definition.key,
    name = definition.name,
    service_type = definition.service_type,
    definition = definition,
    cwd = definition.cwd,
    env = vim.deepcopy(definition.env),
    metadata = vim.deepcopy(definition.metadata or {}),
    status = "STOPPED",
    generation = 0,
    restart_count = 0,
    subscribers = {},
    output = nil,
    output_bufnr = nil,
    terminal_output = false,
    process = nil,
    process_group_id = nil,
    restart_timer = nil,
    health_timer = nil,
    kill_timer = nil,
    disposed = false,
  }, Service)
  self.services[service.key] = service
  self:_ensure_output(service)
  self:_emit(service, "registered")
  return service
end

function Runtime:reconcile(root, definitions, selected_keys)
  local selected = {}
  for _, key in ipairs(selected_keys or {}) do
    selected[key] = true
  end
  local discovered = {}
  for _, definition in ipairs(definitions or {}) do
    discovered[definition.key] = definition
    if selected[definition.key] then
      local service = self:register(definition)
      service.selected = true
    end
  end

  for key, service in pairs(self.services) do
    if service.metadata.project_root == root and not selected[key] then
      service.selected = false
      if not active_statuses[service.status] then
        self:dispose(key)
      else
        self:_emit(service, "deselected")
      end
    end
  end
  return self:list(root)
end

function Runtime:get(key)
  return self.services[key]
end

function Runtime:list(root)
  local services = {}
  for _, service in pairs(self.services) do
    if not root or service.metadata.project_root == root then table.insert(services, service) end
  end
  table.sort(services, function(a, b) return a.name < b.name end)
  return services
end

function Runtime:subscribe(callback)
  if type(callback) ~= "function" then return function() end end
  table.insert(self.subscribers, callback)
  return function()
    for index, subscriber in ipairs(self.subscribers) do
      if subscriber == callback then
        table.remove(self.subscribers, index)
        break
      end
    end
  end
end

function Runtime:start(key, opts)
  opts = opts or {}
  local service = self:get(key)
  if self.shutting_down or not service or service.disposed or active_statuses[service.status] then return false end

  self:_cancel_restart(service)
  if not opts.auto_restart then service.restart_count = 0 end
  service.generation = service.generation + 1
  local generation = service.generation
  local profile = opts.profile
  if profile == nil then profile = service.metadata.profile end
  self:_reset_metadata(service, profile)

  local renderer = self:_ensure_output(service)
  renderer:clear()
  service.output_bufnr = renderer.bufnr
  service.terminal_output = false
  service.process_group_id = nil
  service.stop_requested = false
  service.restart_after_stop = false
  service.status = "STARTING"
  self:_emit(service, "starting")

  local command = vim.deepcopy(service.definition.cmd)
  if type(service.definition.prepare) == "function" then
    local ok, prepared = pcall(service.definition.prepare, service.definition, profile)
    if not ok or type(prepared) ~= "table" or not prepared[1] then
      service.status = "FAILED"
      service.last_error = ok and "invalid prepared command" or prepared
      renderer:push("stderr", "[start error] " .. tostring(service.last_error) .. "\n")
      self:_emit(service, "failed", service.last_error)
      return false
    end
    command = prepared
  end

  local ok, process = pcall(self.spawn, command, {
    cwd = service.cwd,
    env = service.env,
    on_output = function(stream, err, data)
      self:_on_output(service, generation, stream, err, data)
    end,
  }, function(result)
    self:_on_exit(service, generation, result)
  end)
  if not ok or not process then
    service.status = "FAILED"
    service.last_error = ok and "failed to start service" or process
    renderer:push("stderr", "[start error] " .. tostring(service.last_error) .. "\n")
    self:_emit(service, "failed", service.last_error)
    return false
  end
  if service.generation ~= generation or service.status ~= "STARTING" then
    kill_process(process, 15)
    return false
  end

  service.process = process
  service.process_group_id = process.group_id
  service.status = "RUNNING"
  self:_start_health_check(service, generation)
  self:_emit(service, "started")
  return true
end

function Runtime:stop(key, opts)
  opts = opts or {}
  local service = self:get(key)
  if not service then return false end

  if service.status == "RESTART_PENDING" then
    self:_cancel_restart(service)
    service.status = "STOPPED"
    self:_emit(service, "stopped")
    return true
  end
  if not active_statuses[service.status] then return false end

  if service.status == "STARTING" and not service.process then
    service.generation = service.generation + 1
    service.status = "STOPPED"
    self:_emit(service, "stopped")
    return true
  end

  service.stop_requested = true
  service.restart_after_stop = opts.restart == true
  service.restart_profile = opts.profile or service.metadata.profile
  service.status = "STOPPING"
  self:_emit(service, "stopping")
  if service.process then
    kill_process(service.process, 15)
    self:_schedule_escalation(service, service.process, service.generation)
  end
  return true
end

function Runtime:restart(key, opts)
  opts = opts or {}
  local service = self:get(key)
  if not service then return false end
  if active_statuses[service.status] then return self:stop(key, { restart = true, profile = opts.profile }) end
  return self:start(key, opts)
end

function Runtime:dispose(key)
  local service = self:get(key)
  if not service then return false end

  service.disposed = true
  service.generation = service.generation + 1
  self:_cancel_restart(service)
  self:_stop_health_check(service)
  close_timer(service.kill_timer)
  service.kill_timer = nil
  kill_process(service.process, 15)
  service.process = nil
  if service.output then service.output:dispose() end
  self.services[key] = nil
  self:_emit(service, "disposed")
  return true
end

function Runtime:get_output_bufnr(key)
  local service = self:get(key)
  if not service then return nil end
  self:_ensure_output(service)
  return service.output_bufnr
end

function Runtime:ensure_output(key)
  local service = self:get(key)
  if not service then return nil end
  return self:_ensure_output(service).bufnr
end

function Runtime:reset_output(key)
  local service = self:get(key)
  if not service then return nil end
  local renderer = self:_ensure_output(service)
  renderer:clear()
  service.output_bufnr = renderer.bufnr
  service.terminal_output = false
  self:_emit(service, "output_replaced")
  return renderer.bufnr
end

function Runtime:append_output(key, stream, data)
  local service = self:get(key)
  if not service or type(data) ~= "string" or data == "" then return false end
  local renderer = self:_ensure_output(service)
  renderer:push(stream == "stderr" and "stderr" or "stdout", data)
  return true
end

function Runtime:replace_output(key, bufnr, opts)
  local service = self:get(key)
  if not service or not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then return nil end
  service.output_bufnr = bufnr
  service.terminal_output = opts and opts.terminal == true or false
  self:_emit(service, "output_replaced")
  return bufnr
end

function Runtime:archive_terminal_output(key, terminal_bufnr)
  local service = self:get(key)
  if not service or service.output_bufnr ~= terminal_bufnr then return false end
  local renderer = self:_ensure_output(service)
  if not renderer:archive_from_buffer(terminal_bufnr) then return false end
  service.output_bufnr = renderer.bufnr
  service.terminal_output = false
  self:_emit(service, "output_archived")
  return true
end

function Runtime:set_debugging(key, debugging)
  local service = self:get(key)
  if not service then return false end
  service.metadata.debugging = debugging == true
  service.status = debugging and "DEBUGGING" or (service.process and "RUNNING" or "STOPPED")
  self:_emit(service, debugging and "debug_started" or "debug_stopped")
  return true
end

function Runtime:is_debugging(key)
  local service = self:get(key)
  return service and service.status == "DEBUGGING" or false
end

function Runtime:start_all(opts)
  local started = 0
  for _, service in ipairs(self:list()) do
    if not active_statuses[service.status] and service.status ~= "RESTART_PENDING" then
      if self:start(service.key, opts) then started = started + 1 end
    end
  end
  return started
end

function Runtime:stop_all()
  local stopped = 0
  for _, service in ipairs(self:list()) do
    if self:stop(service.key) then stopped = stopped + 1 end
  end
  return stopped
end

function Runtime:begin_shutdown()
  if self.shutting_down then return false end
  self.shutting_down = true

  for _, service in ipairs(self:list()) do
    self:_cancel_restart(service)
    self:_stop_health_check(service)
    close_timer(service.kill_timer)
    service.kill_timer = nil
    service.restart_after_stop = false
    service.restart_profile = nil

    if service.status == "RESTART_PENDING" then
      service.stop_requested = false
      service.status = "STOPPED"
      self:_emit(service, "stopped")
    elseif service.process then
      service.stop_requested = true
      service.status = "STOPPING"
      self:_emit(service, "stopping")
      kill_process(service.process, 15)
    elseif service.process_group_id then
      signal_process_group(service.process_group_id, 15)
    end
  end
  return true
end

function Runtime:is_shutdown_complete()
  for _, service in ipairs(self:list()) do
    if service.process then return false end
    if service.process_group_id then
      if signal_process_group(service.process_group_id, 0) then return false end
      service.process_group_id = nil
    end
  end
  return true
end

function Runtime:force_shutdown()
  self.shutting_down = true
  for _, service in ipairs(self:list()) do
    self:_cancel_restart(service)
    self:_stop_health_check(service)
    close_timer(service.kill_timer)
    service.kill_timer = nil
    service.restart_after_stop = false
    service.restart_profile = nil

    if service.status == "RESTART_PENDING" then
      service.stop_requested = false
      service.status = "STOPPED"
      self:_emit(service, "stopped")
    elseif service.process then
      kill_process(service.process, 9)
    elseif service.process_group_id then
      signal_process_group(service.process_group_id, 9)
    end
  end
  return self:is_shutdown_complete()
end

function M.new(opts)
  opts = opts or {}
  return setmetatable({
    services = {},
    subscribers = {},
    spawn = opts.spawn or default_spawn,
    output_limit = opts.output_limit or 10000,
    kill_timeout_ms = opts.kill_timeout_ms or 3000,
    shutting_down = false,
  }, Runtime)
end

local default_runtime

function M.setup(opts)
  if not default_runtime then default_runtime = M.new(opts) end
  return default_runtime
end

function M.instance()
  return default_runtime or M.setup()
end

for _, method in ipairs({
  "register", "reconcile", "get", "list", "subscribe", "start", "stop", "restart", "dispose",
  "get_output_bufnr", "ensure_output", "reset_output", "append_output", "replace_output", "archive_terminal_output", "set_debugging",
  "is_debugging", "start_all", "stop_all", "begin_shutdown", "is_shutdown_complete", "force_shutdown",
}) do
  local method_name = method
  M[method_name] = function(...)
    local runtime = M.instance()
    return runtime[method_name](runtime, ...)
  end
end

return M
