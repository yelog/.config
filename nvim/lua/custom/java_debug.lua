local M = {}

local active_task
local active_session
local active_terminal_buf
local active_build_process
local launch_token
local pending_config
local listeners_configured = false

local function notify(message, level)
  vim.notify("Java debug: " .. message, level or vim.log.levels.INFO)
end

local function touch(task)
  local ok, task_list = pcall(require, "overseer.task_list")
  if ok then task_list.touch(task) end
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

function M.launch_config(task)
  local metadata = task.metadata or {}
  return {
    type = "java",
    request = "launch",
    name = "Debug " .. (task.name or vim.fs.basename(metadata.main_class or "Java")),
    mainClass = metadata.main_class,
    projectName = metadata.project_name,
    cwd = metadata.project_root,
    console = "integratedTerminal",
  }
end

function M.debug_build_command(task, profile)
  local command = vim.deepcopy((task.metadata or {}).debug_build_cmd)
  if type(command) ~= "table" or not command[1] then return nil end

  local executable = vim.fs.basename(tostring(command[1]))
  if profile and profile ~= "" and (executable == "mvn" or executable == "mvnw" or executable == "mvn.cmd") then
    table.insert(command, 2, "-P" .. profile)
  end
  return command
end

function M.ensure_output_buffer(task)
  local strategy = task and task.strategy
  if not strategy then return nil end

  local bufnr = strategy.bufnr
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then return bufnr end

  bufnr = vim.api.nvim_create_buf(false, true)
  strategy.bufnr = bufnr
  vim.bo[bufnr].buflisted = false
  vim.b[bufnr].overseer_task = task.id
  vim.api.nvim_buf_call(bufnr, function()
    vim.bo[bufnr].filetype = "OverseerOutput"
  end)
  touch(task)
  return bufnr
end

function M.prepare_build(task, profile, callback, runner)
  local command = M.debug_build_command(task, profile)
  if not command then
    callback(true)
    return
  end

  notify("preparing " .. task.name .. " for Debug")
  runner = runner or function(cmd, opts, done) vim.system(cmd, opts, done) end
  return runner(command, {
    cwd = task.metadata.project_root,
    text = true,
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

function M.enrich_launch_config(task, bufnr, callback, execute)
  local config = M.launch_config(task)
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

local function set_debugging(task, debugging)
  if not task then return end
  task.metadata = task.metadata or {}
  task.metadata.debugging = debugging
  touch(task)
end

function M.adopt_output_buffer(task, bufnr)
  local strategy = task and task.strategy
  if not strategy then return nil end
  local previous_buf = strategy.bufnr
  strategy.bufnr = bufnr

  local output_win
  if previous_buf and vim.api.nvim_buf_is_valid(previous_buf) then
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == previous_buf then
        vim.api.nvim_win_set_buf(win, bufnr)
        output_win = output_win or win
      end
    end
    if previous_buf ~= bufnr then pcall(vim.api.nvim_buf_delete, previous_buf, { force = true }) end
  end
  return output_win
end

function M.archive_output_buffer(task, terminal_buf)
  if not task or not task.strategy or task.strategy.bufnr ~= terminal_buf then return nil end
  if not terminal_buf or not vim.api.nvim_buf_is_valid(terminal_buf) then return nil end

  local lines = vim.api.nvim_buf_get_lines(terminal_buf, 0, -1, false)
  local archive_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(archive_buf, 0, -1, false, lines)
  vim.bo[archive_buf].modifiable = false
  pcall(vim.api.nvim_buf_set_name, archive_buf, "[dap-log] " .. (task.name or "java-service"))
  M.adopt_output_buffer(task, archive_buf)
  pcall(vim.api.nvim_buf_delete, terminal_buf, { force = true })
  return archive_buf
end

local function archive_active_output()
  if active_task and active_terminal_buf then
    M.archive_output_buffer(active_task, active_terminal_buf)
    active_terminal_buf = nil
    touch(active_task)
  end
end

local function stop_active_build()
  if active_build_process then
    pcall(active_build_process.kill, active_build_process, 15)
    active_build_process = nil
  end
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
    if not active_task or config.__spring_service_task_key ~= active_task.metadata.task_key then
      return default_terminal_buffer()
    end

    local bufnr = vim.api.nvim_create_buf(false, true)
    local output_win = M.adopt_output_buffer(active_task, bufnr)
    active_terminal_buf = bufnr
    vim.bo[bufnr].scrollback = 10000
    touch(active_task)
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
    set_debugging(active_task, false)
    active_task = nil
    active_session = nil
    active_build_process = nil
    launch_token = nil
  end

  dap.listeners.on_session.spring_services = function(_, new)
    if new and active_task and new.config and new.config.__spring_service_task_key == active_task.metadata.task_key then
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
      set_debugging(active_task, true)
    end
  end
end

function M.is_debugging(task)
  return active_task == task and (launch_token ~= nil or active_session ~= nil)
end

function M.terminate(task, callback)
  if not M.is_debugging(task) then
    if callback then callback() end
    return false
  end
  launch_token = nil
  stop_active_build()
  if pending_config then
    pending_config.__cancel_guard = require("dap").ABORT
    pending_config = nil
  end
  local dap = require("dap")
  if not active_session then
    set_debugging(active_task, false)
    active_task = nil
    if callback then vim.schedule(callback) end
    return true
  end
  if dap.session() ~= active_session then dap.set_session(active_session) end
  dap.terminate({
    on_done = function()
      if active_task == task then
        archive_active_output()
        set_debugging(active_task, false)
        active_task = nil
        active_session = nil
      end
      if callback then vim.schedule(callback) end
    end,
  })
  return true
end

function M.terminate_active()
  if active_task then return M.terminate(active_task) end
  require("dap").terminate()
  return true
end

function M.start(task)
  M.setup()
  local metadata = task.metadata or {}
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
  if active_task then
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
  launch_token = token
  active_task = task
  M.ensure_output_buffer(task)
  vim.defer_fn(function()
    if launch_token ~= token or active_task ~= task then return end
    notify("launch preparation timed out; check the build and jdtls import, then try again", vim.log.levels.ERROR)
    M.terminate(task)
  end, 120000)

  local profile = require("overseer.service_state").get_profile(root)
  local function launch()
    M.enrich_launch_config(task, bufnr, function(config, enrich_err)
      vim.schedule(function()
        if launch_token ~= token or active_task ~= task then return end
        if not config then
          active_task = nil
          launch_token = nil
          notify(enrich_err, vim.log.levels.ERROR)
          return
        end
        local resolved, config_err = M.resolve_config(config, root, main_class, profile)
        if not resolved then
          active_task = nil
          launch_token = nil
          notify(config_err, vim.log.levels.ERROR)
          return
        end
        M.start_debug_adapter(bufnr, function(port, adapter_err)
          vim.schedule(function()
            if launch_token ~= token or active_task ~= task then return end
            if not port then
              active_task = nil
              launch_token = nil
              notify(adapter_err, vim.log.levels.ERROR)
              return
            end
            resolved.type = "java_service"
            resolved.__spring_service_task_key = metadata.task_key
            dap.adapters.java_service = { type = "server", host = "127.0.0.1", port = port }
            pending_config = resolved
            vim.api.nvim_buf_call(bufnr, function()
              local ok_run, run_err = pcall(dap.run, resolved)
              if not ok_run then
                active_task = nil
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

  if task.status == "PENDING" and not task.time_start then
    local build_process
    build_process = M.prepare_build(task, profile, function(ok, build_err)
      if active_build_process == build_process then active_build_process = nil end
      if launch_token ~= token or active_task ~= task then return end
      if not ok then
        active_task = nil
        launch_token = nil
        notify("build preparation failed: " .. build_err, vim.log.levels.ERROR)
        return
      end
      launch()
    end)
    active_build_process = build_process
  else
    launch()
  end
end

return M
