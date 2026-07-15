local M = {}

local function find_project_root(start_dir)
  local dir = start_dir
  local last_marker = nil
  while dir and dir ~= "/" do
    if vim.fn.isdirectory(dir .. "/.git") == 1 then return dir end
    if vim.fn.filereadable(dir .. "/package.json") == 1 then last_marker = dir end
    dir = vim.fn.fnamemodify(dir, ":h")
  end
  return last_marker
end

local function parse_package_json(filepath)
  local ok, content = pcall(function()
    local file = io.open(filepath, "r")
    if not file then return nil end
    local result = file:read("*a")
    file:close()
    return result
  end)
  if not ok or not content then return nil end
  local decoded, data = pcall(vim.json.decode, content)
  if not decoded or type(data) ~= "table" then return nil end
  return { name = data.name, scripts = data.scripts or {} }
end

local function detect_package_manager(project_dir)
  if vim.fn.filereadable(project_dir .. "/pnpm-lock.yaml") == 1 then return "pnpm" end
  if vim.fn.filereadable(project_dir .. "/yarn.lock") == 1 then return "yarn" end
  if vim.fn.filereadable(project_dir .. "/package-lock.json") == 1 then return "npm" end
  if vim.fn.filereadable(project_dir .. "/bun.lockb") == 1 then return "bun" end
  if vim.fn.executable("pnpm") == 1 then return "pnpm" end
  if vim.fn.executable("yarn") == 1 then return "yarn" end
  return "npm"
end

local function command_for(package_manager, script)
  if package_manager == "yarn" then return { "yarn", script } end
  if package_manager == "pnpm" then return { "pnpm", "run", script } end
  if package_manager == "bun" then return { "bun", "run", script } end
  return { "npm", "run", script }
end

local dev_scripts = { dev = true, start = true, serve = true, watch = true, develop = true }

local function is_dev_script(name)
  local base = name:match("^[^:]+")
  return dev_scripts[base] == true
end

local function find_package_jsons(root, max_depth)
  local packages = {}
  max_depth = max_depth or 5

  local function scan(dir, depth)
    if depth > max_depth or vim.fn.isdirectory(dir) ~= 1 then return end
    local handle = vim.uv.fs_scandir(dir)
    if not handle then return end
    while true do
      local name, kind = vim.uv.fs_scandir_next(handle)
      if not name then break end
      local path = dir .. "/" .. name
      if kind == "file" and name == "package.json" then
        local package = parse_package_json(path)
        if package and next(package.scripts) then
          package.path = path
          package.dir = dir
          table.insert(packages, package)
        end
      elseif kind == "directory"
        and not name:match("^%.")
        and name ~= "node_modules"
        and name ~= "dist"
        and name ~= "build"
        and name ~= ".next"
        and name ~= ".nuxt" then
        scan(path, depth + 1)
      end
    end
  end

  scan(root, 0)
  return packages
end

local function parse_vite_line(line)
  if line:match("ready in %d+ ms") then return { ready = true } end
  local port = line:match("Local:%s+https?://localhost:(%d+)")
  return port and { port = tonumber(port) } or nil
end

local function parse_nextjs_line(line)
  if not line:match("ready %- started server") then return nil end
  local port = line:match("on%s+[%d%.]+:(%d+)")
  return { ready = true, port = port and tonumber(port) or nil }
end

local function parse_webpack_line(line)
  if not line:match("Project is running at") and not line:match("Local:%s+http://localhost:") then return nil end
  local port = line:match("http://localhost:(%d+)")
  return port and { ready = true, port = tonumber(port) } or nil
end

local function parse_generic_line(line)
  local port = line:match("[Ll]istening on port%s+(%d+)")
    or line:match("[Ss]erver running at%s+https?://localhost:(%d+)")
    or line:match("[Aa]pp listening on port%s+(%d+)")
  return port and { ready = true, port = tonumber(port) } or nil
end

function M.parse_line(metadata, line)
  local result = parse_vite_line(line)
    or parse_nextjs_line(line)
    or parse_webpack_line(line)
    or parse_generic_line(line)
  if not result then return false end

  local changed = false
  if result.ready and not metadata.ready then
    metadata.ready = true
    changed = true
  end
  if result.port and not metadata.port then
    metadata.port = result.port
    metadata.url = string.format("http://localhost:%d", result.port)
    changed = true
  end
  return changed
end

function M.discover(opts)
  local root = find_project_root((opts or {}).dir or vim.fn.getcwd())
  if not root then return {} end

  local packages = find_package_jsons(root)
  local package_manager = detect_package_manager(root)
  local definitions = {}
  local seen = {}
  for _, package in ipairs(packages) do
    local is_monorepo = #packages > 1
    local package_name = package.name or vim.fs.basename(package.dir)
    for script, script_command in pairs(package.scripts) do
      if not vim.tbl_contains({ "postinstall", "preinstall", "prepare", "version", "prepublishOnly" }, script) then
        local name = is_monorepo and (package_name .. ":" .. script) or script
        if not seen[name] then
          seen[name] = true
          local is_dev = is_dev_script(script)
          table.insert(definitions, {
            key = "npm::" .. package.dir .. "::" .. script,
            name = name,
            service_type = "npm",
            cmd = command_for(package_manager, script),
            cwd = package.dir,
            env = { FORCE_COLOR = "1", CLICOLOR_FORCE = "1" },
            restart = { auto = is_dev, delay = 3, max_attempts = 3 },
            color_policy = "always",
            parse_line = M.parse_line,
            metadata = {
              service_type = "npm",
              npm = true,
              ready = false,
              project_root = root,
              package_dir = package.dir,
              package_name = package_name,
              script = script,
              script_cmd = script_command,
              package_manager = package_manager,
            },
          })
        end
      end
    end
  end
  table.sort(definitions, function(a, b)
    local a_dev = is_dev_script(a.metadata.script) and 0 or 1
    local b_dev = is_dev_script(b.metadata.script) and 0 or 1
    if a_dev ~= b_dev then return a_dev < b_dev end
    return a.name < b.name
  end)
  return definitions
end

return M
