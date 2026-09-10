local M = {}

local function is_java_home(home)
  return type(home) == "string" and home ~= "" and vim.fn.executable(home .. "/bin/java") == 1
end

local function java_version(home)
  local result = vim.system({ home .. "/bin/java", "-version" }, { text = true }):wait()
  if result.code ~= 0 then
    return nil
  end
  local output = (result.stdout or "") .. (result.stderr or "")
  local version = output:match('version%s+"([^"]+)"')
  if not version then
    return nil
  end
  if version:match("^1%.") then
    return tonumber(version:match("^1%.(%d+)"))
  end
  return tonumber(version:match("^(%d+)"))
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
  if candidates_dir == "/.sdkman/candidates" then return {} end
  return vim.fn.glob(candidates_dir .. "/java/*", false, true)
end

function M.discover(env, opts)
  env = env or vim.env
  opts = opts or {}
  local valid_home = opts.is_java_home or is_java_home
  local get_version = opts.version or java_version
  local by_version = {}
  local seen_paths = {}
  local launcher_candidates = {}

  local function add_home(home, source)
    if not home or seen_paths[home] or not valid_home(home) then return end
    local version = get_version(home)
    if not version then return end
    seen_paths[home] = true
    if not by_version[version] then by_version[version] = home end
    if version >= 21 then table.insert(launcher_candidates, { home = home, source = source, version = version }) end
  end

  add_home(env.NVIM_JAVA_HOME, "explicit")
  for _, key in ipairs({ "JAVA_HOME_8", "JAVA_HOME_11", "JAVA_HOME_17", "JAVA_HOME_21", "JAVA_HOME" }) do
    add_home(env[key], key == "JAVA_HOME_21" and "env21" or "env")
  end
  for _, home in ipairs(opts.sdkman_homes or sdkman_java_homes(env)) do
    add_home(home, "sdkman")
  end

  local versions = vim.tbl_keys(by_version)
  table.sort(versions)
  table.sort(launcher_candidates, function(a, b)
    local priority = { explicit = 3, env21 = 2, sdkman = 1, env = 0 }
    if priority[a.source] ~= priority[b.source] then return priority[a.source] > priority[b.source] end
    return a.version < b.version
  end)
  local launcher = launcher_candidates[1] and launcher_candidates[1].home or nil

  local runtimes = {}
  for _, version in ipairs(versions) do
    local runtime = {
      name = runtime_name(version),
      path = by_version[version],
    }
    if runtime.path == launcher then
      runtime.default = true
    end
    table.insert(runtimes, runtime)
  end
  return runtimes, launcher
end

return M
