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

function M.discover(env, opts)
  env = env or vim.env
  opts = opts or {}
  local valid_home = opts.is_java_home or is_java_home
  local get_version = opts.version or java_version
  local by_version = {}
  local seen_paths = {}

  for _, key in ipairs({ "JAVA_HOME_8", "JAVA_HOME_11", "JAVA_HOME_17", "JAVA_HOME_21", "JAVA_HOME" }) do
    local home = env[key]
    if home and not seen_paths[home] and valid_home(home) then
      local version = get_version(home)
      if version and not by_version[version] then
        by_version[version] = home
        seen_paths[home] = true
      end
    end
  end

  local versions = vim.tbl_keys(by_version)
  table.sort(versions)
  local launcher_version
  for _, version in ipairs(versions) do
    if version >= 21 then
      launcher_version = version
      break
    end
  end
  local launcher = launcher_version and by_version[launcher_version] or nil

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
