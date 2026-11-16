local M = {}
local cached_discovery
local minimum_launcher_version = 25
local priorities = { explicit = 3, env25 = 2, sdkman = 1, env = 0 }

local function canonical_home(home)
  if type(home) == "string" and home ~= "" then
    return vim.uv.fs_realpath(home) or home
  end
end

local function is_java_home(home)
  return type(home) == "string" and home ~= "" and vim.fn.executable(home .. "/bin/java") == 1
end

local function java_version(home)
  local readable, lines = pcall(vim.fn.readfile, home .. "/release")
  if readable then
    for _, line in ipairs(lines) do
      local version = line:match('^JAVA_VERSION="([^"]+)"')
      if version and version:match("^%d+") then
        return version
      end
    end
  end

  local ok, result = pcall(function()
    return vim.system({ home .. "/bin/java", "-version" }, { text = true, timeout = 3000 }):wait()
  end)
  if not ok or result.code ~= 0 then
    return nil
  end
  return ((result.stdout or "") .. (result.stderr or "")):match('version%s+"([^"]+)"')
end

local function version_parts(version)
  if version == nil then
    return nil
  end
  local parts = {}
  for part in tostring(version):gmatch("%d+") do
    parts[#parts + 1] = tonumber(part)
  end
  if parts[1] == 1 and parts[2] then
    table.remove(parts, 1)
  end
  return parts[1] and parts or nil
end

local function file_identity(path)
  local stat = vim.uv.fs_stat(path)
  if not stat then
    return ""
  end
  return table.concat({ stat.ino, stat.size, stat.mtime.sec, stat.mtime.nsec }, ":")
end

local function prefer_launcher(first, second)
  if first.source ~= second.source then
    return priorities[first.source] > priorities[second.source]
  end
  if first.version[1] ~= second.version[1] then
    return first.version[1] < second.version[1]
  end
  for index = 2, math.max(#first.version, #second.version) do
    local first_part = first.version[index] or 0
    local second_part = second.version[index] or 0
    if first_part ~= second_part then
      return first_part > second_part
    end
  end
  return first.home < second.home
end

local function runtime_name(version)
  if version == 8 then
    return "JavaSE-1.8"
  end
  return "JavaSE-" .. version
end

local function sdkman_java_homes(env)
  local candidates_dir = env.SDKMAN_CANDIDATES_DIR
  if not candidates_dir and env.SDKMAN_DIR then
    candidates_dir = env.SDKMAN_DIR .. "/candidates"
  end
  candidates_dir = candidates_dir or ((env.HOME or "") .. "/.sdkman/candidates")
  if candidates_dir == "/.sdkman/candidates" then
    return {}
  end
  return vim.fn.glob(candidates_dir .. "/java/*", false, true)
end

function M.discover(env, opts)
  env = env or vim.env
  opts = opts or {}
  local valid_home = opts.is_java_home or is_java_home
  local get_version = opts.version or java_version
  local by_version = {}
  local seen_paths = {}
  local candidates = {}
  local launcher_candidates = {}
  local project_home = canonical_home(env.JAVA_HOME)
  local explicit_home = canonical_home(env.NVIM_JAVA_HOME)

  local function add_home(home, source)
    home = canonical_home(home)
    if not home then
      return
    end
    local existing = seen_paths[home]
    if existing then
      if priorities[source] > priorities[existing.source] then
        existing.source = source
      end
      return
    end
    if not valid_home(home) then
      return
    end
    local candidate = { home = home, source = source }
    seen_paths[home] = candidate
    table.insert(candidates, candidate)
  end

  add_home(env.NVIM_JAVA_HOME, "explicit")
  for _, key in ipairs({ "JAVA_HOME_8", "JAVA_HOME_11", "JAVA_HOME_17", "JAVA_HOME_21", "JAVA_HOME_25", "JAVA_HOME" }) do
    add_home(env[key], key == "JAVA_HOME_25" and "env25" or "env")
  end
  for _, home in ipairs(opts.sdkman_homes or sdkman_java_homes(env)) do
    add_home(home, "sdkman")
  end

  local cacheable = not opts.version and not opts.is_java_home
  local identities = {}
  if cacheable then
    for _, candidate in ipairs(candidates) do
      table.insert(identities, {
        candidate.home,
        candidate.source,
        file_identity(candidate.home .. "/release"),
        file_identity(candidate.home .. "/bin/java"),
      })
    end
  end
  local cache_key
  if cacheable then
    cache_key = vim.json.encode({
      candidates = identities,
      project_home = project_home,
      explicit_home = explicit_home,
    })
  end
  if cacheable and cached_discovery and cached_discovery.key == cache_key then
    return vim.deepcopy(cached_discovery.runtimes), cached_discovery.launcher, cached_discovery.error
  end

  for _, candidate in ipairs(candidates) do
    local version = version_parts(get_version(candidate.home))
    if version then
      candidate.version = version
      if not by_version[version[1]] then
        by_version[version[1]] = candidate.home
      end
      if version[1] >= minimum_launcher_version then
        table.insert(launcher_candidates, candidate)
      end
    else
      cacheable = false
    end
  end

  table.sort(launcher_candidates, prefer_launcher)
  local launcher = launcher_candidates[1]
  local launcher_error
  local explicit = explicit_home and seen_paths[explicit_home]
  if explicit_home and (not explicit or not explicit.version or explicit.version[1] < minimum_launcher_version) then
    launcher = nil
    launcher_error = "NVIM_JAVA_HOME must point to JDK 25 or newer: " .. env.NVIM_JAVA_HOME
  elseif not launcher then
    launcher_error = "Java language servers require JDK 25 or newer; set NVIM_JAVA_HOME or JAVA_HOME_25"
  end
  if launcher then
    by_version[launcher.version[1]] = launcher.home
  end
  local project = project_home and seen_paths[project_home]
  if project and project.version then
    by_version[project.version[1]] = project.home
  end
  local versions = vim.tbl_keys(by_version)
  table.sort(versions)
  local launcher_home = launcher and launcher.home or nil
  local default_home = project and project.version and project.home or launcher_home

  local runtimes = {}
  for _, version in ipairs(versions) do
    local runtime = {
      name = runtime_name(version),
      path = by_version[version],
    }
    if runtime.path == default_home then
      runtime.default = true
    end
    table.insert(runtimes, runtime)
  end
  if cacheable then
    cached_discovery = {
      key = cache_key,
      runtimes = vim.deepcopy(runtimes),
      launcher = launcher_home,
      error = launcher_error,
    }
  end
  return runtimes, launcher_home, launcher_error
end

return M
