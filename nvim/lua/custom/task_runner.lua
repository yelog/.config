local M = {}

local last_task

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

local function java_task(action, context)
  local root = context.root
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

  if exists(root .. "/mvnw", context) or exists(root .. "/pom.xml", context) then
    local executable = exists(root .. "/mvnw", context) and "./mvnw" or "mvn"
    if action == "all" then
      return task("Test all (Maven)", { executable, "test" }, root)
    end
    return task("Test " .. target, { executable, "-Dtest=" .. target, "test" }, root)
  end

  if
    exists(root .. "/gradlew", context)
    or exists(root .. "/build.gradle", context)
    or exists(root .. "/build.gradle.kts", context)
  then
    local executable = exists(root .. "/gradlew", context) and "./gradlew" or "gradle"
    if action == "all" then
      return task("Test all (Gradle)", { executable, "test" }, root)
    end
    target = target:gsub("#", ".")
    return task("Test " .. target, { executable, "test", "--tests", target }, root)
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

function M.run(action)
  local definition, err = M.build(action)
  if not definition then
    vim.notify(err, vim.log.levels.WARN)
    return
  end
  last_task = require("overseer").new_task(definition)
  last_task:start()
end

function M.rerun()
  if not last_task then
    vim.notify("No test task has been run", vim.log.levels.WARN)
    return
  end
  last_task:restart(true)
end

function M.open_output()
  if last_task and last_task:get_bufnr() then
    last_task:open_output("horizontal")
  else
    require("overseer").open({ enter = true })
  end
end

return M
