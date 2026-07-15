local M = {}

local active_service_key
local active_session
local active_terminal_buf
local active_build_process
local active_build_group_id
local launch_token
local pending_config
local listeners_configured = false
local shutdown_in_progress = false

local function notify(message, level)
  vim.notify("Java debug: " .. message, level or vim.log.levels.INFO)
end

local function service_key(service_or_key)
  if type(service_or_key) == "table" then return service_or_key.key end
  return service_or_key
end

local function get_service(service_or_key)
  if type(service_or_key) == "table" then return service_or_key end
  local key = service_key(service_or_key)
  return key and require("services.runtime").get(key) or nil
end

local function runtime()
  return require("services.runtime").instance()
end

local function append_words(...)
  local values = {}
  for index = 1, select("#", ...) do
    local value = select(index, ...)
    if type(value) == "table" then value = table.concat(value, " ") end
    if type(value) == "string" and value ~= "" then table.insert(values, value) end
  end
  return #values > 0 and table.concat(values, " ") or nil
end

function M.bundles(mason_root)
  mason_root = mason_root or (vim.fn.stdpath("data") .. "/mason")
  local debug_pattern = mason_root .. "/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar"
  local bundles = vim.fn.glob(debug_pattern, false, true)
  table.sort(bundles)
  return bundles
end

function M.toolchain_fingerprint(mason_root, extra_bundles)
  mason_root = mason_root or (vim.fn.stdpath("data") .. "/mason")
  local files = {}
  for _, pattern in ipairs({
    mason_root .. "/packages/jdtls/plugins/*.jar",
    mason_root .. "/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar",
  }) do
    for _, path in ipairs(vim.fn.glob(pattern, false, true)) do
      table.insert(files, path)
    end
  end
  vim.list_extend(files, extra_bundles or {})
  table.sort(files)
  local identities = {}
  for _, path in ipairs(files) do
    local stat = vim.uv.fs_stat(path)
    local mtime = stat and stat.mtime or {}
    table.insert(identities, table.concat({
      vim.fs.basename(path),
      stat and stat.size or 0,
      mtime.sec or 0,
      mtime.nsec or 0,
    }, ":"))
  end
  return vim.fn.sha256(table.concat(identities, "\n")):sub(1, 12)
end

function M.launch_config(service)
  local metadata = service.metadata or {}
  return {
    type = "java",
    request = "launch",
    name = "Debug " .. (service.name or vim.fs.basename(metadata.main_class or "Java")),
    mainClass = metadata.main_class,
    projectName = metadata.project_name,
    cwd = metadata.project_root,
    console = "internalConsole",
  }
end

function M.debug_build_command(service, profile)
  local command = vim.deepcopy((service.metadata or {}).debug_build_cmd)
  if type(command) ~= "table" or not command[1] then return nil end

  local executable = vim.fs.basename(tostring(command[1]))
  if profile and profile ~= "" and (executable == "mvn" or executable == "mvnw" or executable == "mvn.cmd") then
    table.insert(command, 2, "-P" .. profile)
  end
  return command
end

function M.ensure_output_buffer(service_or_key)
  local key = service_key(service_or_key)
  return key and runtime():ensure_output(key) or nil
end

function M.route_output(session, event)
  local config = session and session.config
  local key = config and config.__service_key
  if not key or config.console ~= "internalConsole" or type(event) ~= "table" or type(event.output) ~= "string" then
    return false
  end
  local stream = event.category == "stderr" and "stderr" or "stdout"
  return runtime():append_output(key, stream, event.output)
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

local function default_build_runner(command, opts, done)
  local system = vim.system(command, opts, done)
  if not opts.detach then return system end

  return {
    pid = system.pid,
    group_id = system.pid,
    system = system,
    kill = function(_, signal)
      if signal_process_group(system.pid, signal) then return true end
      return pcall(system.kill, system, signal)
    end,
  }
end

function M.prepare_build(service, profile, callback, runner)
  local command = M.debug_build_command(service, profile)
  if not command then
    callback(true)
    return
  end

  notify("preparing " .. service.name .. " for Debug")
  runner = runner or default_build_runner
  return runner(command, {
    cwd = service.metadata.project_root,
    text = true,
    detach = supports_process_groups(),
  }, function(result)
    vim.schedule(function()
      if result.code == 0 then
        callback(true)
        return
      end

      local detail = vim.trim(result.stderr or result.stdout or "")
      if detail == "" then detail = "build exited with code " .. result.code end
      callback(false, detail)
    end)
  end)
end

function M.enrich_launch_config(service, bufnr, callback, execute)
  local config = M.launch_config(service)
  local main_class = config.mainClass
  local project_name = config.projectName
  execute = execute or require("jdtls.util").execute_command

  local function fail(err, fallback)
    callback(nil, (err and (err.message or tostring(err))) or fallback)
  end

  execute({ command = "vscode.java.resolveJavaExecutable", arguments = { main_class, project_name } }, function(java_err, java_exec)
    if java_err or not java_exec then
      fail(java_err, "could not resolve Java executable for " .. main_class)
      return
    end
    config.javaExec = java_exec

    execute({ command = "vscode.java.resolveClasspath", arguments = { main_class, project_name } }, function(path_err, paths)
      if path_err or not paths then
        fail(path_err, "could not resolve classpath for " .. main_class)
        return
      end
      config.modulePaths = paths[1] or {}
      config.classPaths = paths[2] or {}

      local preview_args = vim.json.encode({
        className = main_class,
        projectName = project_name,
        inheritedOptions = true,
        expectedOptions = { ["org.eclipse.jdt.core.compiler.problem.enablePreviewFeatures"] = "enabled" },
      })
      execute({ command = "vscode.java.checkProjectSettings", arguments = preview_args }, function(preview_err, preview)
        if preview_err then
          fail(preview_err, "could not resolve preview-feature settings for " .. main_class)
          return
        end
        if preview then config.vmArgs = "--enable-preview" end
        callback(config, nil)
      end, bufnr)
    end, bufnr)
  end, bufnr)
end

function M.start_debug_adapter(bufnr, callback, execute)
  execute = execute or require("jdtls.util").execute_command
  execute({ command = "vscode.java.startDebugSession" }, function(err, port)
    if err or not port then
      callback(nil, (err and (err.message or tostring(err))) or "could not start Java debug adapter")
      return
    end
    callback(port, nil)
  end, bufnr)
end

local function load_project_config(root)
  local path = root .. "/.nvim/java-debug.json"
  if vim.fn.filereadable(path) ~= 1 then return {}, nil end

  local ok_read, lines = pcall(vim.fn.readfile, path)
  if not ok_read then return nil, "cannot read " .. path end
  local ok_decode, config = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not ok_decode or type(config) ~= "table" then return nil, "invalid JSON in " .. path end
  if config.defaults ~= nil and type(config.defaults) ~= "table" then
    return nil, "defaults must be an object in " .. path
  end
  if config.services ~= nil and type(config.services) ~= "table" then
    return nil, "services must be an object in " .. path
  end
  return config, nil
end

function M.resolve_config(base, root, main_class, profile)
  local project, err = load_project_config(root)
  if not project then return nil, err end

  local defaults = project.defaults or {}
  local service = (project.services or {})[main_class] or {}
  if type(service) ~= "table" then
    return nil, "service " .. main_class .. " must be an object in " .. root .. "/.nvim/java-debug.json"
  end

  local resolved = vim.tbl_deep_extend("force", {}, base, defaults, service)
  resolved.vmArgs = append_words(
    base.vmArgs,
    defaults.vmArgs,
    service.vmArgs,
    profile and ("-Dspring.profiles.active=" .. profile) or nil
  )
  resolved.name = "Debug " .. vim.fs.basename(main_class:gsub("%.", "/"))
    .. (profile and (" [" .. profile .. "]") or "")
  return resolved, nil
end

function M.match_config(configs, main_class, module_root, project_name)
  local matches = {}
  for _, config in ipairs(configs or {}) do
    if config.mainClass == main_class then table.insert(matches, config) end
  end
  if #matches == 0 then return nil, "no launch configuration found for " .. main_class end
  if #matches == 1 then return matches[1], nil end

  for _, expected_name in ipairs({ project_name, module_root and vim.fs.basename(module_root) or nil }) do
    for _, config in ipairs(matches) do
      if expected_name and config.projectName == expected_name then return config, nil end
    end
  end
  return nil, "multiple launch configurations found for " .. main_class
end

local function set_debugging(service_or_key, debugging)
  local key = service_key(service_or_key)
  if key then runtime():set_debugging(key, debugging) end
end

function M.adopt_output_buffer(service_or_key, bufnr)
  local key = service_key(service_or_key)
  if not key or not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then return nil end
  local service_runtime = runtime()
  local previous_buf = service_runtime:get_output_bufnr(key)
  local output_win
  if previous_buf then
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == previous_buf then
        vim.api.nvim_win_set_buf(win, bufnr)
        output_win = output_win or win
      end
    end
  end
  service_runtime:replace_output(key, bufnr, { terminal = true })
  return output_win
end

function M.archive_output_buffer(service_or_key, terminal_buf)
  local key = service_key(service_or_key)
  if not key or not terminal_buf or not vim.api.nvim_buf_is_valid(terminal_buf) then return nil end
  local service_runtime = runtime()
  if not service_runtime:archive_terminal_output(key, terminal_buf) then return nil end
  local archive_buf = service_runtime:get_output_bufnr(key)
  pcall(vim.api.nvim_buf_delete, terminal_buf, { force = true })
  return archive_buf
end

local function archive_active_output()
  if active_service_key and active_terminal_buf then
    M.archive_output_buffer(active_service_key, active_terminal_buf)
    active_terminal_buf = nil
  end
end

local function stop_active_build(signal, keep_reference)
  if active_build_process then
    pcall(active_build_process.kill, active_build_process, signal or 15)
  elseif active_build_group_id then
    signal_process_group(active_build_group_id, signal or 15)
  end
  if not keep_reference then
    active_build_process = nil
    if not shutdown_in_progress then active_build_group_id = nil end
  end
end

local function cancel_pending_config()
  if pending_config then
    local ok, dap = pcall(require, "dap")
    if ok then pending_config.__cancel_guard = dap.ABORT end
    pending_config = nil
  end
end

local function active_terminal_job()
  if not active_terminal_buf or not vim.api.nvim_buf_is_valid(active_terminal_buf) then return nil, nil end
  local jobid = tonumber(vim.b[active_terminal_buf].terminal_job_id)
  if not jobid or jobid <= 0 then return nil, nil end
  return jobid, tonumber(vim.fn.jobpid(jobid))
end

function M.cleanup_stale_terminals()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr)
      and vim.api.nvim_buf_get_name(bufnr):find("[dap-terminal]", 1, true) then
      pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
    end
  end
end

local function default_terminal_buffer()
  local current_win = vim.api.nvim_get_current_win()
  vim.cmd("belowright new")
  local bufnr = vim.api.nvim_get_current_buf()
  local terminal_win = vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_win(current_win)
  return bufnr, terminal_win
end

function M.setup()
  if listeners_configured then return end
  local ok, dap = pcall(require, "dap")
  if not ok then return end
  listeners_configured = true

  local function terminal_win_cmd(config)
    if not active_service_key or config.__service_key ~= active_service_key then
      return default_terminal_buffer()
    end

    local bufnr = vim.api.nvim_create_buf(false, true)
    local output_win = M.adopt_output_buffer(active_service_key, bufnr)
    active_terminal_buf = bufnr
    vim.bo[bufnr].scrollback = 10000
    return bufnr, output_win
  end
  dap.defaults.java.terminal_win_cmd = terminal_win_cmd
  dap.defaults.java_service.terminal_win_cmd = terminal_win_cmd

  local function belongs_to_service(session)
    return session and session == active_session
  end
  local function clear_debugging(session)
    if session and not belongs_to_service(session) then return end
    archive_active_output()
    set_debugging(active_service_key, false)
    active_service_key = nil
    active_session = nil
    active_build_process = nil
    if not shutdown_in_progress then active_build_group_id = nil end
    launch_token = nil
    if not active_build_group_id then shutdown_in_progress = false end
  end

  dap.listeners.on_session.spring_services = function(_, new)
    if new and active_service_key and new.config and new.config.__service_key == active_service_key then
      active_session = new
      pending_config = nil
      new.on_close.spring_services = function(session)
        vim.schedule(function() clear_debugging(session) end)
      end
    end
  end
  dap.listeners.after.event_initialized.spring_services = function(session)
    if belongs_to_service(session) then
      launch_token = nil
      set_debugging(active_service_key, true)
    end
  end
  dap.listeners.after.event_output.spring_services = function(session, event)
    if not belongs_to_service(session) then return end
    M.route_output(session, event)
  end
end

function M.is_debugging(service_or_key)
  return active_service_key == service_key(service_or_key) and (launch_token ~= nil or active_session ~= nil)
end

function M.terminate(service_or_key, callback)
  local key = service_key(service_or_key)
  if not M.is_debugging(key) then
    if callback then callback() end
    return false
  end
  launch_token = nil
  stop_active_build()
  cancel_pending_config()
  local dap = require("dap")
  if not active_session then
    set_debugging(active_service_key, false)
    active_service_key = nil
    if callback then vim.schedule(callback) end
    return true
  end
  if dap.session() ~= active_session then dap.set_session(active_session) end
  dap.terminate({
    on_done = function()
      if active_service_key == key then
        archive_active_output()
        set_debugging(active_service_key, false)
        active_service_key = nil
        active_session = nil
      end
      if callback then vim.schedule(callback) end
    end,
  })
  return true
end

function M.begin_shutdown()
  local key = active_service_key
  if not key and not active_build_process and not active_build_group_id then return false end

  shutdown_in_progress = true
  launch_token = nil
  stop_active_build(15, true)
  cancel_pending_config()
  if not active_session then
    if key then
      set_debugging(key, false)
      active_service_key = nil
    end
    return true
  end

  local ok, dap = pcall(require, "dap")
  if not ok then return false end
  if dap.session() ~= active_session then pcall(dap.set_session, active_session) end
  dap.terminate({
    on_done = function()
      if active_service_key ~= key then return end
      archive_active_output()
      set_debugging(key, false)
      active_service_key = nil
      active_session = nil
    end,
  })
  return true
end

function M.is_shutdown_complete()
  if active_build_group_id and not signal_process_group(active_build_group_id, 0) then
    active_build_group_id = nil
  end
  return active_service_key == nil
    and active_session == nil
    and active_build_process == nil
    and active_build_group_id == nil
    and active_terminal_buf == nil
end

function M.force_shutdown()
  local key = active_service_key
  shutdown_in_progress = true
  launch_token = nil
  stop_active_build(9, true)
  active_build_process = nil
  cancel_pending_config()

  local jobid, pid = active_terminal_job()
  if jobid then pcall(vim.fn.jobstop, jobid) end
  if pid and pid > 0 then pcall(vim.uv.kill, pid, 9) end
  if active_session and not active_session.closed and type(active_session.close) == "function" then
    pcall(active_session.close, active_session)
  end

  active_terminal_buf = nil
  active_session = nil
  active_service_key = nil
  if key then set_debugging(key, false) end
  return true
end

function M.terminate_active()
  if active_service_key then return M.terminate(active_service_key) end
  require("dap").terminate()
  return true
end

function M.start(service_or_key)
  M.setup()
  local service = get_service(service_or_key)
  if not service or not service.key then
    notify("service metadata is incomplete; reopen the Services panel", vim.log.levels.ERROR)
    return
  end
  local metadata = service.metadata or {}
  local root = metadata.project_root
  local main_class = metadata.main_class
  local source = metadata.source
  if not root or not main_class or not source then
    notify("service metadata is incomplete; reopen the Services panel", vim.log.levels.ERROR)
    return
  end
  if #M.bundles() == 0 then
    notify("java-debug-adapter is missing; run :MasonToolsInstall, restart Neovim, then reopen a Java file",
      vim.log.levels.ERROR)
    return
  end

  local dap = require("dap")
  if active_service_key then
    notify("a service debug launch is already active; terminate it with <leader>dt first", vim.log.levels.WARN)
    return
  end
  if dap.session() then
    notify("another DAP session is active; terminate it before debugging a service", vim.log.levels.WARN)
    return
  end
  M.cleanup_stale_terminals()

  local bufnr = vim.fn.bufadd(source)
  vim.fn.bufload(bufnr)
  local clients = vim.lsp.get_clients({ name = "jdtls", bufnr = bufnr })
  if #clients == 0 then
    notify("jdtls is not attached to " .. source .. "; open the file and wait for project import", vim.log.levels.ERROR)
    return
  end

  local commands = ((clients[1].server_capabilities.executeCommandProvider or {}).commands or {})
  if not vim.tbl_contains(commands, "vscode.java.startDebugSession") then
    notify("jdtls did not load Java Debug; run :MasonToolsInstall and :JdtRestart", vim.log.levels.ERROR)
    return
  end

  local token = {}
  shutdown_in_progress = false
  launch_token = token
  active_service_key = service.key
  runtime():reset_output(service.key)
  vim.defer_fn(function()
    if launch_token ~= token or active_service_key ~= service.key then return end
    notify("launch preparation timed out; check the build and jdtls import, then try again", vim.log.levels.ERROR)
    M.terminate(service.key)
  end, 120000)

  local profile = require("services.state").get_profile(root)
  local function launch()
    M.enrich_launch_config(service, bufnr, function(config, enrich_err)
      vim.schedule(function()
        if launch_token ~= token or active_service_key ~= service.key then return end
        if not config then
          active_service_key = nil
          launch_token = nil
          notify(enrich_err, vim.log.levels.ERROR)
          return
        end
        local resolved, config_err = M.resolve_config(config, root, main_class, profile)
        if not resolved then
          active_service_key = nil
          launch_token = nil
          notify(config_err, vim.log.levels.ERROR)
          return
        end
        M.start_debug_adapter(bufnr, function(port, adapter_err)
          vim.schedule(function()
            if launch_token ~= token or active_service_key ~= service.key then return end
            if not port then
              active_service_key = nil
              launch_token = nil
              notify(adapter_err, vim.log.levels.ERROR)
              return
            end
            resolved.type = "java_service"
            resolved.__service_key = service.key
            dap.adapters.java_service = { type = "server", host = "127.0.0.1", port = port }
            pending_config = resolved
            vim.api.nvim_buf_call(bufnr, function()
              local ok_run, run_err = pcall(dap.run, resolved)
              if not ok_run then
                active_service_key = nil
                launch_token = nil
                pending_config = nil
                notify(tostring(run_err), vim.log.levels.ERROR)
              end
            end)
          end)
        end)
      end)
    end)
  end

  local build_process
  build_process = M.prepare_build(service, profile, function(ok, build_err)
    if active_build_process == build_process then
      active_build_process = nil
      if not shutdown_in_progress then active_build_group_id = nil end
    end
    if launch_token ~= token or active_service_key ~= service.key then return end
    if not ok then
      active_service_key = nil
      launch_token = nil
      notify("build preparation failed: " .. build_err, vim.log.levels.ERROR)
      return
    end
    launch()
  end)
  active_build_process = build_process
  active_build_group_id = build_process and build_process.group_id or nil
end

return M
