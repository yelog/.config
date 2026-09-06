local M = {}

local last_task
local last_service

local web_filetypes = {
  javascript = true,
  javascriptreact = true,
  typescript = true,
  typescriptreact = true,
  vue = true,
}

local function exists(path, context)
  if context.files ~= nil then
    return context.files[path] == true
  end
  return vim.fn.filereadable(path) == 1 or vim.fn.isdirectory(path) == 1
end

local function relative_path(root, path)
  local prefix = root:gsub("/+$", "") .. "/"
  if path:sub(1, #prefix) == prefix then
    return path:sub(#prefix + 1)
  end
  return path
end

local function nearest_match(lines, cursor_line, patterns)
  for line_nr = math.min(cursor_line or #lines, #lines), 1, -1 do
    for _, pattern in ipairs(patterns) do
      local match = lines[line_nr]:match(pattern)
      if match then
        return match
      end
    end
  end
end

local function task(name, cmd, cwd)
  return {
    name = name,
    cmd = cmd,
    cwd = cwd,
    components = {
      { "on_output_quickfix", open = false, open_on_match = false },
      { "on_complete_notify", statuses = { "FAILURE" } },
      "default",
    },
  }
end

local function prepare_maven_test(definition, profile)
  local command = vim.deepcopy(definition.cmd)
  local executable = vim.fs.basename(tostring(command[1] or ""))
  if type(profile) == "string" and profile ~= ""
    and (executable == "mvn" or executable == "mvnw" or executable == "mvn.cmd") then
    table.insert(command, 2, "-P" .. profile)
  end
  return command
end

local function maven_context(context)
  local root = context.maven_root
  local module_pom = context.module_pom
  if not root or not module_pom then
    local ok, maven = pcall(require, "maven")
    if ok then
      root = root or maven.find_project_root(context.file)
      module_pom = module_pom or maven.find_nearest_pom(context.file)
    end
  end
  root = root or context.root
  return root, module_pom
end

local function java_task(action, context)
  local lines = context.lines or {}
  local class = vim.fs.basename(context.file):gsub("%.java$", "")
  local package_name
  for _, line in ipairs(lines) do
    package_name = line:match("^%s*package%s+([%w_.]+)%s*;")
    if package_name then
      break
    end
  end
  local qualified_class = package_name and (package_name .. "." .. class) or class
  local target = qualified_class
  if action == "nearest" then
    local method = nearest_match(lines, context.cursor_line, {
      "[%w_<>,%[%]?]+%s+([%w_]+)%s*%(",
    })
    if method then
      target = qualified_class .. "#" .. method
    end
  end

  local maven_root, module_pom = maven_context(context)
  if exists(maven_root .. "/mvnw", context) or exists(maven_root .. "/pom.xml", context) then
    local executable = exists(maven_root .. "/mvnw", context) and "./mvnw" or "mvn"
    local cmd = { executable }
    if action ~= "all" and module_pom then
      local module = relative_path(maven_root, vim.fs.dirname(module_pom))
      if module ~= "." and module ~= vim.fs.dirname(module_pom) then
        vim.list_extend(cmd, { "-pl", module, "-am" })
      end
    end
    table.insert(cmd, "-Dmoss.skipTests=false")
    if action == "all" then
      table.insert(cmd, "test")
      return task("Test all (Maven)", cmd, maven_root)
    end
    vim.list_extend(cmd, { "-Dsurefire.failIfNoSpecifiedTests=false", "-Dtest=" .. target, "test" })
    local definition = task("Test " .. target, cmd, maven_root)
    local display_name = target:match("([%w_$]+#[%w_$]+)$") or target:match("([%w_$]+)$") or target
    definition.service = {
      key = "test::" .. vim.fn.sha256(maven_root .. "\0" .. target):sub(1, 16),
      name = display_name,
      service_type = "test",
      project_root = maven_root,
      target = target,
    }
    return definition
  end

  if
    exists(context.root .. "/gradlew", context)
    or exists(context.root .. "/build.gradle", context)
    or exists(context.root .. "/build.gradle.kts", context)
  then
    local executable = exists(context.root .. "/gradlew", context) and "./gradlew" or "gradle"
    if action == "all" then
      return task("Test all (Gradle)", { executable, "test" }, context.root)
    end
    target = target:gsub("#", ".")
    return task("Test " .. target, { executable, "test", "--tests", target }, context.root)
  end

  return nil, "No Maven or Gradle build found"
end

local function vitest_command(root, context)
  if exists(root .. "/pnpm-lock.yaml", context) then
    return { "pnpm", "exec", "vitest", "run" }
  elseif exists(root .. "/yarn.lock", context) then
    return { "yarn", "vitest", "run" }
  elseif exists(root .. "/bun.lock", context) or exists(root .. "/bun.lockb", context) then
    return { "bun", "x", "vitest", "run" }
  end
  return { "npx", "--no-install", "vitest", "run" }
end

local function web_task(action, context)
  local cmd = vitest_command(context.root, context)
  if action ~= "all" then
    table.insert(cmd, relative_path(context.root, context.file))
  end
  if action == "nearest" then
    local test_name = nearest_match(context.lines or {}, context.cursor_line, {
      "[%w_.]+%s*%(%s*['\"](.-)['\"]",
    })
    if test_name then
      vim.list_extend(cmd, { "-t", test_name })
    end
  end
  return task(
    action == "all" and "Test all (Vitest)" or "Test " .. relative_path(context.root, context.file),
    cmd,
    context.root
  )
end

local function rust_task(action, context)
  local cmd = { "cargo", "test" }
  if action == "nearest" then
    local test_name = nearest_match(context.lines or {}, context.cursor_line, {
      "^%s*fn%s+([%w_]+)%s*%(",
    })
    if test_name then
      table.insert(cmd, test_name)
    end
  elseif action == "file" then
    local integration_test = relative_path(context.root, context.file):match("^tests/([^/]+)%.rs$")
    if integration_test then
      vim.list_extend(cmd, { "--test", integration_test })
    end
  end
  return task(action == "all" and "Test all (Cargo)" or "Test Rust target", cmd, context.root)
end

local function lua_task(action, context)
  local tests_dir = context.root .. "/tests"
  if action == "all" and (exists(tests_dir, context) or context.root:match("/nvim$")) then
    local script = string.format(
      'for test in %q/tests/*_spec.lua; do nvim --headless -u NONE "+luafile ${test}" "+qa!" || exit 1; done',
      context.root
    )
    return task("Test all (Neovim headless)", { "zsh", "-lc", script }, context.root)
  end
  if context.file:match("_spec%.lua$") or context.root:match("/nvim$") then
    return task(
      "Test " .. vim.fs.basename(context.file),
      { "nvim", "--headless", "-u", "NONE", "+luafile " .. context.file, "+qa!" },
      context.root
    )
  end
  local cmd = { "busted" }
  if action ~= "all" then
    table.insert(cmd, relative_path(context.root, context.file))
  end
  return task(action == "all" and "Test all (Busted)" or "Test " .. vim.fs.basename(context.file), cmd, context.root)
end

local function root_markers(filetype)
  if filetype == "java" then
    return { "mvnw", "gradlew", "pom.xml", "build.gradle", "build.gradle.kts", ".git" }
  elseif web_filetypes[filetype] then
    return { "package.json", "pnpm-lock.yaml", "yarn.lock", "package-lock.json", "bun.lock", ".git" }
  elseif filetype == "rust" then
    return { "Cargo.toml", ".git" }
  elseif filetype == "lua" then
    return { ".luarc.json", "stylua.toml", "init.lua", ".git" }
  end
  return { ".git" }
end

function M.context(bufnr)
  bufnr = bufnr or 0
  local file = vim.api.nvim_buf_get_name(bufnr)
  local filetype = vim.bo[bufnr].filetype
  local root = vim.fs.root(file, root_markers(filetype)) or vim.fn.getcwd()
  return {
    root = root,
    file = file,
    filetype = filetype,
    cursor_line = vim.api.nvim_win_get_cursor(0)[1],
    lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
  }
end

function M.build(action, context)
  context = context or M.context()
  if context.filetype == "java" then
    return java_task(action, context)
  elseif web_filetypes[context.filetype] then
    return web_task(action, context)
  elseif context.filetype == "rust" then
    return rust_task(action, context)
  elseif context.filetype == "lua" then
    return lua_task(action, context)
  end
  return nil, "No test runner for " .. (context.filetype or "unknown filetype")
end

local function run_service(definition)
  local service_info = definition.service
  local panel = require("services.panel").instance()
  local active_panel = panel:open(service_info.project_root)
  local runtime = require("services.runtime").instance()
  local service = runtime:register({
    key = service_info.key,
    name = service_info.name,
    service_type = service_info.service_type,
    cmd = definition.cmd,
    cwd = definition.cwd,
    color_policy = "preserve",
    prepare = prepare_maven_test,
    metadata = {
      service_type = service_info.service_type,
      project_root = service_info.project_root,
      test_target = service_info.target,
    },
  })
  local profile = require("services.state").get_profile(service_info.project_root)
  runtime:restart(service.key, { profile = profile })
  panel:render(active_panel)
  panel:focus(active_panel, service.key, { follow = true })
  last_service = { key = service.key, root = service_info.project_root }
end

function M.run(action, context)
  local definition, err = M.build(action, context)
  if not definition then
    vim.notify(err, vim.log.levels.WARN)
    return
  end
  if definition.service then
    run_service(definition)
    return
  end
  last_service = nil
  last_task = require("overseer").new_task(definition)
  last_task:start()
end

function M.rerun()
  if last_service then
    local panel = require("services.panel").instance()
    local active_panel = panel:open(last_service.root)
    local profile = require("services.state").get_profile(last_service.root)
    require("services.runtime").instance():restart(last_service.key, { profile = profile })
    panel:render(active_panel)
    panel:focus(active_panel, last_service.key, { follow = true })
    return
  end
  if not last_task then
    vim.notify("No test task has been run", vim.log.levels.WARN)
    return
  end
  last_task:restart(true)
end

function M.open_output()
  if last_service then
    local panel = require("services.panel").instance()
    local active_panel = panel:open(last_service.root)
    panel:focus(active_panel, last_service.key)
    return
  end
  if last_task and last_task:get_bufnr() then
    last_task:open_output("horizontal")
  else
    require("overseer").open({ enter = true })
  end
end

return M
