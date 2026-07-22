local M = {}

local default_state_path = vim.fn.stdpath("state") .. "/maven/profiles.json"
local state_path = default_state_path

local function default_runner(command, opts, callback)
  return vim.system(command, opts, function(result)
    vim.schedule(function()
      callback(result)
    end)
  end)
end

local runner = default_runner

local function empty_state()
  return { projects = {} }
end

local function normalize_root(root)
  if type(root) ~= "string" or root == "" then
    return nil
  end
  return vim.fs.normalize(root)
end

local function normalize_profiles(profiles)
  local normalized = {}
  local seen = {}
  for _, profile in ipairs(profiles or {}) do
    if type(profile) == "string" then
      profile = vim.trim(profile)
      if profile ~= "" and not seen[profile] then
        seen[profile] = true
        table.insert(normalized, profile)
      end
    end
  end
  table.sort(normalized)
  return normalized
end

local function normalize_arguments(arguments)
  local normalized = {}
  for _, argument in ipairs(arguments or {}) do
    if type(argument) == "table" and type(argument.arg) == "string" then
      local arg = vim.trim(argument.arg)
      local value = type(argument.value) == "string" and vim.trim(argument.value) or nil
      if arg ~= "" then
        table.insert(normalized, { arg = arg, value = value ~= "" and value or nil, enabled = argument.enabled == true })
      end
    end
  end
  return normalized
end

local function normalize_commands(commands)
  local normalized = {}
  local seen = {}
  for _, command in ipairs(commands or {}) do
    if type(command) == "table" and type(command.name) == "string" and type(command.cmd_args) == "table" then
      local name = vim.trim(command.name)
      local args = {}
      for _, arg in ipairs(command.cmd_args) do
        if type(arg) == "string" and vim.trim(arg) ~= "" then table.insert(args, arg) end
      end
      if name ~= "" and #args > 0 and not seen[name] then
        seen[name] = true
        table.insert(normalized, {
          name = name,
          description = type(command.description) == "string" and command.description or "",
          cmd_args = args,
        })
      end
    end
  end
  return normalized
end

local function load_state()
  if vim.fn.filereadable(state_path) ~= 1 then
    return empty_state()
  end

  local ok_read, lines = pcall(vim.fn.readfile, state_path)
  local ok_decode, state = pcall(vim.json.decode, ok_read and table.concat(lines, "\n") or "")
  if not ok_decode or type(state) ~= "table" or type(state.projects) ~= "table" then
    return empty_state()
  end
  return state
end

local function ensure_state_parent()
  local directory = vim.fs.dirname(state_path)
  local ok, result = pcall(vim.fn.mkdir, directory, "p")
  return ok and (result ~= 0 or vim.fn.isdirectory(directory) == 1)
end

local function save_state(state)
  if not ensure_state_parent() then
    return false
  end

  local ok_encode, encoded = pcall(vim.json.encode, state)
  if not ok_encode then
    return false
  end

  local temporary_path = string.format("%s.tmp.%d.%d", state_path, vim.uv.os_getpid(), vim.uv.hrtime())
  local ok_write, result = pcall(vim.fn.writefile, { encoded }, temporary_path)
  if not ok_write or result ~= 0 then
    pcall(vim.fn.delete, temporary_path)
    return false
  end

  if not vim.uv.fs_rename(temporary_path, state_path) then
    pcall(vim.fn.delete, temporary_path)
    return false
  end
  return true
end

local function current_path()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    path = vim.fn.getcwd()
  end
  if vim.fn.isdirectory(path) ~= 1 then
    path = vim.fs.dirname(path)
  end
  return path
end

local function maven_config()
  local ok, config = pcall(require, "maven.config")
  return ok and config or nil
end

function M.find_project_root(path)
  path = path or current_path()
  if type(path) ~= "string" or path == "" then
    return nil
  end
  if vim.fn.isdirectory(path) ~= 1 then
    path = vim.fs.dirname(path)
  end

  local workspace_root = vim.fs.root(path, { "mvnw", ".git" })
  if workspace_root and vim.fn.filereadable(workspace_root .. "/pom.xml") == 1 then
    return vim.fs.normalize(workspace_root)
  end

  local pom_root = vim.fs.root(path, { "pom.xml" })
  return pom_root and vim.fs.normalize(pom_root) or nil
end

function M.parse_profiles(output)
  local profiles = {}
  for line in (output or ""):gmatch("[^\r\n]+") do
    local profile = line:match("Profile%s+Id:%s*(.-)%s*%(") or line:match("Profile%s+Id:%s*(%S+)")
    if profile then
      table.insert(profiles, profile)
    end
  end
  return normalize_profiles(profiles)
end

function M.get_profiles(root)
  root = normalize_root(root)
  if not root then
    return {}
  end

  local project = load_state().projects[root]
  if type(project) ~= "table" then
    return {}
  end
  return normalize_profiles(project.profiles)
end

function M.set_profiles(root, profiles)
  root = normalize_root(root)
  if not root or type(profiles) ~= "table" then
    return false
  end

  local state = load_state()
  local normalized = normalize_profiles(profiles)
  if #normalized == 0 then
    state.projects[root] = nil
  else
    state.projects[root] = { profiles = normalized }
  end
  return save_state(state)
end

local function get_project_setting(root, name, normalize)
  root = normalize_root(root)
  if not root then return {} end
  local project = load_state().projects[root]
  return type(project) == "table" and normalize(project[name]) or {}
end

local function set_project_setting(root, name, value, normalize)
  root = normalize_root(root)
  if not root or type(value) ~= "table" then return false end
  local state = load_state()
  local project = state.projects[root]
  if type(project) ~= "table" then project = {} end
  local normalized = normalize(value)
  if #normalized == 0 then
    project[name] = nil
  else
    project[name] = normalized
  end
  state.projects[root] = project
  return save_state(state)
end

function M.get_arguments(root)
  return get_project_setting(root, "arguments", normalize_arguments)
end

function M.set_arguments(root, arguments)
  return set_project_setting(root, "arguments", arguments, normalize_arguments)
end

function M.get_commands(root)
  return get_project_setting(root, "commands", normalize_commands)
end

function M.set_commands(root, commands)
  return set_project_setting(root, "commands", commands, normalize_commands)
end

function M.get_primary_profile(root)
  return M.get_profiles(root)[1]
end

function M.apply_profiles(profiles, config)
  config = config or maven_config()
  local defaults = config and config.options and config.options.default_arguments_view
  if type(defaults) ~= "table" then
    return false
  end

  local arguments = {}
  for _, argument in ipairs(defaults.arguments or {}) do
    if argument._maven_dashboard_profile ~= true then
      table.insert(arguments, argument)
    end
  end

  local selected = normalize_profiles(profiles)
  if #selected > 0 then
    table.insert(arguments, {
      arg = "-P",
      value = table.concat(selected, ","),
      enabled = true,
      _maven_dashboard_profile = true,
    })
  end
  defaults.arguments = arguments
  return true
end

function M.save_current_arguments(root, config)
  root = root or M.find_project_root()
  config = config or maven_config()
  local defaults = config and config.options and config.options.default_arguments_view
  if not root or type(defaults) ~= "table" then return false end

  local arguments = {}
  for _, argument in ipairs(defaults.arguments or {}) do
    if argument._maven_dashboard_profile ~= true then table.insert(arguments, argument) end
  end
  return M.set_arguments(root, arguments)
end

local arguments_persistence_installed = false

function M.install_argument_persistence()
  if arguments_persistence_installed then return true end
  local ok, argument_view = pcall(require, "maven.ui.arguments_view")
  if not ok then return false end

  local upstream_mount = argument_view.mount
  argument_view.mount = function(self, ...)
    upstream_mount(self, ...)
    local input = self._input_component and self._input_component.bufnr
    local options = self._options_component and self._options_component.bufnr
    local group = vim.api.nvim_create_augroup("MavenArgumentsPersistence", { clear = true })
    local function persist_on_leave(buffer)
      vim.api.nvim_create_autocmd("BufLeave", {
        group = group,
        buffer = buffer,
        callback = function()
          vim.schedule(function()
            local current = vim.api.nvim_get_current_buf()
            if current ~= input and current ~= options then M.save_current_arguments() end
          end)
        end,
      })
    end
    persist_on_leave(input)
    persist_on_leave(options)
  end
  arguments_persistence_installed = true
  return true
end

function M.apply_current(root, config)
  root = root or M.find_project_root()
  if not root then
    return false
  end
  config = config or maven_config()
  if not config or not config.options then return false end
  local defaults = config.options.default_arguments_view
  if type(defaults) == "table" then defaults.arguments = M.get_arguments(root) end
  local projects_view = config.options.projects_view
  if type(projects_view) == "table" then projects_view.custom_commands = M.get_commands(root) end
  M.install_argument_persistence()
  return M.apply_profiles(M.get_profiles(root), config)
end

local function open_upstream(command)
  local root = M.find_project_root()
  if not root then
    vim.notify("No Maven project found for the current buffer", vim.log.levels.WARN)
    return false
  end
  vim.cmd("cd " .. vim.fn.fnameescape(root))
  vim.cmd(command)
  return true
end

function M.open_dashboard()
  return open_upstream("Maven")
end

function M.open_execution()
  return open_upstream("MavenExec")
end

function M.open_favorites()
  return open_upstream("MavenFavorites")
end

local function ensure_maven_plugin()
  if maven_config() then
    return true
  end

  local ok_lazy, lazy = pcall(require, "lazy")
  if not ok_lazy then
    return false, "lazy.nvim is unavailable"
  end
  local ok_load, err = pcall(lazy.load, { plugins = { "maven.nvim" } })
  if not ok_load then
    return false, tostring(err)
  end
  if not maven_config() then
    return false, "maven.nvim did not load"
  end
  return true
end

local function maven_executable()
  local config = maven_config()
  if config and config.options and type(config.options.mvn_executable) == "string" then
    return config.options.mvn_executable
  end
  return "mvn"
end

function M.list_available(root, callback)
  root = normalize_root(root)
  local pom_path = root and root .. "/pom.xml" or nil
  if not pom_path or vim.fn.filereadable(pom_path) ~= 1 then
    callback("No Maven project found: pom.xml is required", nil)
    return nil
  end

  local command = {
    maven_executable(),
    "--batch-mode",
    "--non-recursive",
    "--file",
    pom_path,
    "help:all-profiles",
  }
  local ok, handle = pcall(runner, command, { cwd = root, text = true }, function(result)
    if not result or result.code ~= 0 then
      local detail = result and vim.trim(result.stderr or result.stdout or "") or "unknown failure"
      callback("Failed to list Maven profiles: " .. detail, nil)
      return
    end
    callback(nil, M.parse_profiles(result.stdout))
  end)
  if not ok then
    callback("Failed to start Maven: " .. tostring(handle), nil)
    return nil
  end
  return handle
end

local function show_picker(root, available)
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    vim.notify("fzf-lua is required to select Maven profiles", vim.log.levels.ERROR)
    return
  end

  local selected = {}
  for _, profile in ipairs(M.get_profiles(root)) do
    selected[profile] = true
  end

  local entries = { "__clear__\tx [no Maven profiles]" }
  for _, profile in ipairs(available) do
    local mark = selected[profile] and "*" or " "
    table.insert(entries, string.format("%s\t%s %s", profile, mark, profile))
  end

  fzf.fzf_exec(entries, {
    prompt = "Maven Profiles (Tab multi-select)> ",
    fzf_opts = { ["--multi"] = true, ["--delimiter"] = "\t", ["--with-nth"] = "2.." },
    actions = {
      enter = function(chosen)
        local chosen_profiles = {}
        local clear = false
        for _, entry in ipairs(chosen or {}) do
          local profile = entry:match("^([^\t]+)")
          if profile == "__clear__" then
            clear = true
          elseif profile then
            table.insert(chosen_profiles, profile)
          end
        end
        if clear then
          chosen_profiles = {}
        end
        if not M.set_profiles(root, chosen_profiles) then
          vim.notify("Failed to save Maven profile selection", vim.log.levels.ERROR)
          return
        end
        M.apply_current(root)
        local message = #chosen_profiles > 0 and table.concat(normalize_profiles(chosen_profiles), ", ") or "none"
        vim.notify("Maven profiles: " .. message)
      end,
    },
  })
end

function M.select()
  local root = M.find_project_root()
  if not root then
    vim.notify("No Maven project found for the current buffer", vim.log.levels.WARN)
    return
  end

  local ok, err = ensure_maven_plugin()
  if not ok then
    vim.notify("Unable to load maven.nvim: " .. err, vim.log.levels.ERROR)
    return
  end

  M.list_available(root, function(list_error, available)
    if list_error then
      vim.notify(list_error, vim.log.levels.ERROR)
    elseif #available == 0 then
      vim.notify("No Maven profiles are available", vim.log.levels.INFO)
    else
      show_picker(root, available)
    end
  end)
end

function M.clear()
  local root = M.find_project_root()
  if not root then
    vim.notify("No Maven project found for the current buffer", vim.log.levels.WARN)
    return
  end
  if not M.set_profiles(root, {}) then
    vim.notify("Failed to clear Maven profile selection", vim.log.levels.ERROR)
    return
  end
  M.apply_current(root)
  vim.notify("Maven profiles: none")
end

function M.add_command(name, cmd_args, description)
  local root = M.find_project_root()
  if not root then
    vim.notify("No Maven project found for the current buffer", vim.log.levels.WARN)
    return false
  end
  local commands = {}
  for _, command in ipairs(M.get_commands(root)) do
    if command.name ~= name then table.insert(commands, command) end
  end
  table.insert(commands, { name = name, description = description or "", cmd_args = cmd_args })
  if not M.set_commands(root, commands) then
    vim.notify("Failed to save Maven command preset", vim.log.levels.ERROR)
    return false
  end
  M.apply_current(root)
  vim.notify("Saved Maven preset: " .. name)
  return true
end

function M.remove_command(name)
  local root = M.find_project_root()
  if not root then
    vim.notify("No Maven project found for the current buffer", vim.log.levels.WARN)
    return false
  end
  local commands = {}
  for _, command in ipairs(M.get_commands(root)) do
    if command.name ~= name then table.insert(commands, command) end
  end
  if not M.set_commands(root, commands) then
    vim.notify("Failed to remove Maven command preset", vim.log.levels.ERROR)
    return false
  end
  M.apply_current(root)
  vim.notify("Removed Maven preset: " .. name)
  return true
end

function M.setup(opts)
  opts = opts or {}
  state_path = opts.path or default_state_path
  runner = opts.runner or default_runner

  vim.api.nvim_create_user_command("MavenProfiles", M.select, {
    desc = "Select Maven profiles",
    force = true,
  })
  vim.api.nvim_create_user_command("MavenProfilesClear", M.clear, {
    desc = "Clear Maven profile selection",
    force = true,
  })
  vim.api.nvim_create_user_command("MavenPresetAdd", function(command)
    local values = vim.split(command.args, "%s+", { trimempty = true })
    local name = table.remove(values, 1)
    if not name or #values == 0 then
      vim.notify("Usage: MavenPresetAdd <name> <Maven arguments...>", vim.log.levels.ERROR)
      return
    end
    M.add_command(name, values)
  end, { nargs = "+", desc = "Add a project Maven command preset" })
  vim.api.nvim_create_user_command("MavenPresetRemove", function(command)
    M.remove_command(command.args)
  end, { nargs = 1, desc = "Remove a project Maven command preset" })
  vim.api.nvim_create_autocmd("DirChanged", {
    group = vim.api.nvim_create_augroup("MavenProfiles", { clear = true }),
    callback = function()
      M.apply_current()
    end,
  })
  vim.api.nvim_create_autocmd("DirChangedPre", {
    group = vim.api.nvim_create_augroup("MavenArgumentsSave", { clear = true }),
    callback = function() M.save_current_arguments() end,
  })
  M.apply_current()
  return M
end

return M
