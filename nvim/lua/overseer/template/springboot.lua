local files = require("overseer.files")

local M = {}

-- Find project root by looking for .git or topmost pom.xml/build.gradle
local function find_project_root(start_dir)
  local dir = start_dir
  local last_marker = nil
  while dir and dir ~= "/" do
    if vim.fn.isdirectory(dir .. "/.git") == 1 then
      return dir
    end
    if vim.fn.filereadable(dir .. "/pom.xml") == 1
      or vim.fn.filereadable(dir .. "/build.gradle") == 1
      or vim.fn.filereadable(dir .. "/build.gradle.kts") == 1 then
      last_marker = dir
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end
  return last_marker
end

-- Check if a file has @SpringBootApplication
local function is_spring_boot_entry(filepath)
  local ok, content = pcall(function()
    local f = io.open(filepath, "r")
    if not f then return "" end
    -- 只读前 4KB，@SpringBootApplication 一定在文件头部
    local c = f:read(4096)
    f:close()
    return c or ""
  end)
  if not ok then return false end
  return content:find("@SpringBootApplication") ~= nil
end

-- Extract class name and package from a Java/Kotlin file
local function extract_class_info(filepath)
  local ok, content = pcall(function()
    local f = io.open(filepath, "r")
    if not f then return "" end
    -- 只读前 2KB，package 声明一定在文件头部
    local c = f:read(2048)
    f:close()
    return c or ""
  end)
  if not ok then return nil end

  local pkg = content:match("package%s+([%w%.]+)%s*;")
  local classname = vim.fn.fnamemodify(filepath, ":t:r") -- filename without extension

  if pkg and classname then
    return {
      package = pkg,
      classname = classname,
      fqn = pkg .. "." .. classname,
    }
  end
  return nil
end

-- Find Spring Boot entry points in a directory tree
local function find_entry_points(dir, max_depth)
  max_depth = max_depth or 15
  local results = {}

  local function scan(d, depth)
    if depth > max_depth then return end
    if not vim.fn.isdirectory(d) == 1 then return end

    local handle = vim.loop.fs_scandir(d)
    if not handle then return end

    while true do
      local name, type = vim.loop.fs_scandir_next(handle)
      if not name then break end

      local path = d .. "/" .. name

      if type == "file" then
        if name:match("%.java$") or name:match("%.kt$") then
          if is_spring_boot_entry(path) then
            local info = extract_class_info(path)
            if info then
              info.path = path
              info.dir = d
              table.insert(results, info)
            end
          end
        end
      elseif type == "directory" then
        -- Skip hidden dirs, build output dirs, node_modules
        if not name:match("^%.") and name ~= "target" and name ~= "build" and name ~= "node_modules" then
          scan(path, depth + 1)
        end
      end
    end
  end

  scan(dir, 0)
  return results
end

-- Check if project uses Spring Boot (has spring-boot-starter in pom.xml or build.gradle)
local function is_spring_boot_project(root)
  local pom = root .. "/pom.xml"
  if vim.fn.filereadable(pom) == 1 then
    local ok, content = pcall(function()
      local f = io.open(pom, "r")
      if not f then return "" end
      local c = f:read("*a")
      f:close()
      return c
    end)
    if ok and (content:find("spring%-boot%-starter") or content:find("spring%-boot") or content:find("SpringBootApplication")) then
      return true
    end
  end

  for _, gradle_file in ipairs({ "build.gradle", "build.gradle.kts" }) do
    local gf = root .. "/" .. gradle_file
    if vim.fn.filereadable(gf) == 1 then
      local ok, content = pcall(function()
        local f = io.open(gf, "r")
        if not f then return "" end
        local c = f:read("*a")
        f:close()
        return c
      end)
      if ok and (content:find("spring%-boot") or content:find("SpringBootApplication")) then
        return true
      end
    end
  end

  return false
end

-- Determine if a dir is a submodule (has its own pom.xml under a parent)
local function find_module_root(entry_dir, project_root)
  local dir = entry_dir
  while dir and dir ~= project_root and dir ~= "/" do
    if vim.fn.filereadable(dir .. "/pom.xml") == 1 then
      return dir
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end
  return project_root
end

return {
  name = "springboot",
  desc = "Auto-detect Spring Boot entry points",
  generator = function(opts)
    local dir = opts.dir or vim.fn.getcwd()
    local root = find_project_root(dir)
    if not root then return {} end
    if not is_spring_boot_project(root) then return {} end

    local entry_points = find_entry_points(root)
    if #entry_points == 0 then return {} end

    -- Detect build tool
    local use_maven = vim.fn.filereadable(root .. "/pom.xml") == 1
    local use_gradle = vim.fn.filereadable(root .. "/build.gradle") == 1
      or vim.fn.filereadable(root .. "/build.gradle.kts") == 1

    -- Find gradlew
    local gradlew = nil
    if use_gradle then
      local gw = root .. "/gradlew"
      if vim.fn.executable(gw) == 1 then
        gradlew = gw
      else
        gradlew = "gradle"
      end
    end

    local ret = {}
    for _, ep in ipairs(entry_points) do
      local module_root = find_module_root(ep.dir, root)
      local is_multi = (module_root ~= root)

      local cmd, cwd
      if use_maven then
        cwd = root
        if is_multi then
          local rel = module_root:sub(#root + 2)
          cmd = { "mvn", "-pl", rel, "spring-boot:run",
                  "-Dspring-boot.run.mainClass=" .. ep.fqn }
        else
          cmd = { "mvn", "spring-boot:run",
                  "-Dspring-boot.run.mainClass=" .. ep.fqn }
        end
      elseif use_gradle then
        cwd = root
        if is_multi then
          local rel = module_root:sub(#root + 2)
          cmd = { gradlew, ":" .. rel .. ":bootRun",
                  "--mainClass=" .. ep.fqn }
        else
          cmd = { gradlew, "bootRun",
                  "--mainClass=" .. ep.fqn }
        end
      end

      if cmd then
        table.insert(ret, {
          name = ep.classname,
          builder = function(params)
            return {
              cmd = cmd,
              cwd = cwd,
              name = ep.classname,
              components = {
                "on_exit_set_status",
                "on_complete_notify",
                {
                  "service.lifecycle",
                  auto_restart = false,
                },
              },
              metadata = {
                service = true,
                group = "springboot",
                module = is_multi and module_root:sub(#root + 2) or nil,
                class = ep.fqn,
                source = ep.path,
              },
            }
          end,
          tags = {},
          params = {},
        })
      end
    end

    return ret
  end,
}
