local M = {}

local default_path = vim.fn.stdpath("state") .. "/overseer/spring-services.json"
local state_path = default_path

local function empty_state()
  return { projects = {} }
end

local function normalize_root(project_root)
  if type(project_root) ~= "string" or project_root == "" then return nil end
  return vim.fs.normalize(project_root)
end

local function load_state()
  if vim.fn.filereadable(state_path) ~= 1 then return empty_state() end

  local ok_read, lines = pcall(vim.fn.readfile, state_path)
  local ok_decode, decoded = pcall(vim.json.decode, ok_read and table.concat(lines, "\n") or "")
  if not ok_decode or type(decoded) ~= "table" or type(decoded.projects) ~= "table" then
    return empty_state()
  end
  return decoded
end

local function ensure_parent()
  local dir = vim.fs.dirname(state_path)
  local ok, result = pcall(vim.fn.mkdir, dir, "p")
  return ok and (result ~= 0 or vim.fn.isdirectory(dir) == 1)
end

local function acquire_lock()
  if not ensure_parent() then return nil end

  local lock_path = state_path .. ".lock"
  local acquired = vim.wait(1000, function()
    if vim.uv.fs_mkdir(lock_path, 448) then return true end

    local stat = vim.uv.fs_stat(lock_path)
    local modified = stat and stat.mtime and stat.mtime.sec or os.time()
    if os.time() - modified > 10 then pcall(vim.uv.fs_rmdir, lock_path) end
    return false
  end, 10)
  return acquired and lock_path or nil
end

local function save_state(state)
  if not ensure_parent() then return false end

  local ok_encode, encoded = pcall(vim.json.encode, state)
  if not ok_encode then return false end

  local temp_path = string.format(
    "%s.tmp.%d.%d",
    state_path,
    vim.uv.os_getpid(),
    vim.uv.hrtime()
  )
  local ok_write, result = pcall(vim.fn.writefile, { encoded }, temp_path)
  if not ok_write or result ~= 0 then
    pcall(vim.fn.delete, temp_path)
    return false
  end

  local renamed = vim.uv.fs_rename(temp_path, state_path)
  if not renamed then
    pcall(vim.fn.delete, temp_path)
    return false
  end
  return true
end

function M.setup(opts)
  opts = opts or {}
  state_path = opts.path or default_path
end

function M.get_profile(project_root)
  local root = normalize_root(project_root)
  if not root then return nil end

  local project = load_state().projects[root]
  if type(project) ~= "table" or type(project.profile) ~= "string" then return nil end
  return project.profile ~= "" and project.profile or nil
end

function M.set_profile(project_root, profile)
  local root = normalize_root(project_root)
  if not root then return false end
  if profile ~= nil and type(profile) ~= "string" then return false end

  local lock_path = acquire_lock()
  if not lock_path then return false end

  local ok, saved = pcall(function()
    local state = load_state()
    if not profile or profile == "" then
      state.projects[root] = nil
    else
      state.projects[root] = { profile = vim.trim(profile) }
    end
    return save_state(state)
  end)
  pcall(vim.uv.fs_rmdir, lock_path)
  return ok and saved or false
end

function M.parse_maven_profiles(project_root)
  local root = normalize_root(project_root)
  if not root then return {} end

  local ok, lines = pcall(vim.fn.readfile, root .. "/pom.xml")
  if not ok then return {} end

  local content = table.concat(lines, "\n"):gsub("<!%-%-[%s%S]-%-%->", "")
  local profiles = {}
  local seen = {}
  for block in content:gmatch("<profile%f[%W][^>]*>([%s%S]-)</profile>") do
    local id = block:match("<id[^>]*>%s*([^<]-)%s*</id>")
    id = id and vim.trim(id) or nil
    if id and id ~= "" and not seen[id] then
      seen[id] = true
      table.insert(profiles, id)
    end
  end
  table.sort(profiles)
  return profiles
end

return M
