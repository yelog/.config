local M = {}

local function find_project_root(start_dir)
  local dir = start_dir
  local last_marker = nil
  while dir and dir ~= "/" do
    if vim.fn.isdirectory(dir .. "/.git") == 1 then return dir end
    if vim.fn.filereadable(dir .. "/pom.xml") == 1
      or vim.fn.filereadable(dir .. "/build.gradle") == 1
      or vim.fn.filereadable(dir .. "/build.gradle.kts") == 1 then
      last_marker = dir
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end
  return last_marker
end

local function read_file(filepath, limit)
  local ok, content = pcall(function()
    local file = io.open(filepath, "r")
    if not file then return "" end
    local result = file:read(limit)
    file:close()
    return result or ""
  end)
  return ok and content or ""
end

local function is_spring_boot_entry(filepath)
  return read_file(filepath, 4096):find("@SpringBootApplication") ~= nil
end

local function extract_class_info(filepath)
  local content = read_file(filepath, 2048)
  local package = content:match("package%s+([%w%.]+)%s*;?")
  local classname = vim.fn.fnamemodify(filepath, ":t:r")
  if not package or not classname then return nil end
  return {
    package = package,
    classname = classname,
    fqn = package .. "." .. classname,
  }
end

local function find_entry_points(dir, max_depth)
  max_depth = max_depth or 15
  local entries = {}

  local function scan(current, depth)
    if depth > max_depth or vim.fn.isdirectory(current) ~= 1 then return end
    local handle = vim.uv.fs_scandir(current)
    if not handle then return end

    while true do
      local name, kind = vim.uv.fs_scandir_next(handle)
      if not name then break end
      local path = current .. "/" .. name
      if kind == "file" and (name:match("%.java$") or name:match("%.kt$")) then
        if is_spring_boot_entry(path) then
          local info = extract_class_info(path)
          if info then
            info.path = path
            info.dir = current
            table.insert(entries, info)
          end
        end
      elseif kind == "directory"
        and not name:match("^%.")
        and name ~= "target"
        and name ~= "build"
        and name ~= "node_modules" then
        scan(path, depth + 1)
      end
    end
  end

  scan(dir, 0)
  return entries
end

local function find_module_root(entry_dir, project_root)
  local dir = entry_dir
  while dir and dir ~= project_root and dir ~= "/" do
    if vim.fn.filereadable(dir .. "/pom.xml") == 1
      or vim.fn.filereadable(dir .. "/build.gradle") == 1
      or vim.fn.filereadable(dir .. "/build.gradle.kts") == 1 then
      return dir
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end
  return project_root
end

local function find_project_name(module_root)
  local pom = module_root .. "/pom.xml"
  if vim.fn.filereadable(pom) ~= 1 then return vim.fs.basename(module_root) end
  local ok, lines = pcall(vim.fn.readfile, pom)
  if not ok then return vim.fs.basename(module_root) end
  local content = table.concat(lines, "\n"):gsub("<parent>.-</parent>", "")
  local artifact_id = content:match("<artifactId>%s*([^<]+)%s*</artifactId>")
  return artifact_id and vim.trim(artifact_id) or vim.fs.basename(module_root)
end

local function parse_server_line(line)
  local supported = false
  for _, server in ipairs({ "Tomcat", "Netty", "Jetty", "Undertow" }) do
    if line:find(server .. " started on port", 1, true) then
      supported = true
      break
    end
  end
  if not supported then return nil end

  local port = line:match("started on port%(s%):%s*(%d+)")
    or line:match("started on port%(s%)%s+(%d+)")
    or line:match("started on port:?%s*(%d+)")
  if not port then return nil end

  local context_path = line:match("context path%s+['\"]([^'\"]*)['\"]") or ""
  if context_path == "/" then
    context_path = ""
  elseif context_path ~= "" and context_path:sub(1, 1) ~= "/" then
    context_path = "/" .. context_path
  end
  return {
    port = tonumber(port),
    protocol = line:match("%((https?)") or "http",
    context_path = context_path,
  }
end

function M.prepare(definition, profile)
  local command = vim.deepcopy(definition.cmd)
  if not profile or profile == "" then return command end

  local executable = vim.fs.basename(tostring(command[1] or ""))
  if executable == "mvn" or executable == "mvnw" or executable == "mvn.cmd" then
    table.insert(command, 2, "-P" .. profile)
  elseif executable == "bash" and command[2] == "-c" and type(command[3]) == "string" then
    command[3] = command[3]:gsub("mvn%s+", "mvn -P" .. profile .. " ", 2)
  end
  return command
end

function M.parse_line(metadata, line)
  local changed = false
  local server = parse_server_line(line)
  if server and not metadata.port then
    for key, value in pairs(server) do
      metadata[key] = value
    end
    metadata.url = string.format("%s://localhost:%d%s", server.protocol, server.port, server.context_path)
    changed = true
  end
  if line:match("Started%s+[%w_.$]+%s+in%s+[%d%.]+%s+seconds") and not metadata.ready then
    metadata.ready = true
    changed = true
  end
  return changed
end

function M.discover(opts)
  local root = find_project_root((opts or {}).dir or vim.fn.getcwd())
  if not root then return {} end

  local use_maven = vim.fn.filereadable(root .. "/pom.xml") == 1
  local use_gradle = vim.fn.filereadable(root .. "/build.gradle") == 1
    or vim.fn.filereadable(root .. "/build.gradle.kts") == 1
  local gradlew = nil
  if use_gradle then
    local candidate = root .. "/gradlew"
    gradlew = vim.fn.executable(candidate) == 1 and candidate or "gradle"
  end

  local definitions = {}
  for _, entry in ipairs(find_entry_points(root)) do
    local module_root = find_module_root(entry.dir, root)
    local is_multi_module = module_root ~= root
    local module = is_multi_module and module_root:sub(#root + 2) or nil
    local command, debug_build_cmd

    if use_maven and is_multi_module then
      local relative = module_root:sub(#root + 2)
      command = {
        "bash",
        "-c",
        string.format("mvn -Dstyle.color=always install -pl %s -am -DskipTests -q && mvn -Dstyle.color=always spring-boot:run -pl %s -Dspring-boot.run.mainClass=%s",
          relative, relative, entry.fqn),
      }
      debug_build_cmd = { "mvn", "-q", "-DskipTests", "install", "-pl", relative, "-am" }
    elseif use_maven then
      command = { "mvn", "-Dstyle.color=always", "spring-boot:run", "-Dspring-boot.run.mainClass=" .. entry.fqn }
      debug_build_cmd = { "mvn", "-q", "-DskipTests", "compile" }
    elseif use_gradle and is_multi_module then
      local relative = module_root:sub(#root + 2):gsub("/", ":")
      command = { gradlew, "--console=rich", ":" .. relative .. ":bootRun", "--mainClass=" .. entry.fqn }
      debug_build_cmd = { gradlew, ":" .. relative .. ":classes" }
    elseif use_gradle then
      command = { gradlew, "--console=rich", "bootRun", "--mainClass=" .. entry.fqn }
      debug_build_cmd = { gradlew, "classes" }
    end

    if command then
      local task_key = module_root .. "::" .. entry.fqn
      table.insert(definitions, {
        key = "springboot::" .. task_key,
        name = entry.classname,
        service_type = "springboot",
        cmd = command,
        cwd = root,
        env = { SPRING_OUTPUT_ANSI_ENABLED = "ALWAYS" },
        restart = { auto = false, delay = 3, max_attempts = 3 },
        color_policy = "always",
        prepare = M.prepare,
        parse_line = M.parse_line,
        metadata = {
          service_type = "springboot",
          springboot = true,
          ready = false,
          project_root = root,
          module = module,
          module_root = module_root,
          project_name = find_project_name(module_root),
          main_class = entry.fqn,
          source = entry.path,
          task_key = task_key,
          debug_build_cmd = debug_build_cmd,
        },
      })
    end
  end
  table.sort(definitions, function(a, b) return a.name < b.name end)
  return definitions
end

return M
