local M = {}

-- Find project root by looking for .git or topmost package.json
local function find_project_root(start_dir)
  local dir = start_dir
  local last_marker = nil
  while dir and dir ~= "/" do
    if vim.fn.isdirectory(dir .. "/.git") == 1 then
      return dir
    end
    if vim.fn.filereadable(dir .. "/package.json") == 1 then
      last_marker = dir
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end
  return last_marker
end

-- Parse package.json and extract scripts
local function parse_package_json(filepath)
  local ok, content = pcall(function()
    local f = io.open(filepath, "r")
    if not f then return nil end
    local c = f:read("*a")
    f:close()
    return c
  end)
  if not ok or not content then return nil end

  -- Use vim.json.decode for robust JSON parsing
  local ok2, data = pcall(vim.json.decode, content)
  if not ok2 or type(data) ~= "table" then return nil end

  return {
    name = data.name,
    scripts = data.scripts or {},
    package_manager = nil, -- will be detected later
  }
end

-- Detect package manager (pnpm/yarn/npm)
local function detect_package_manager(project_dir)
  -- Check for lockfiles in order of preference
  if vim.fn.filereadable(project_dir .. "/pnpm-lock.yaml") == 1 then
    return "pnpm"
  elseif vim.fn.filereadable(project_dir .. "/yarn.lock") == 1 then
    return "yarn"
  elseif vim.fn.filereadable(project_dir .. "/package-lock.json") == 1 then
    return "npm"
  elseif vim.fn.filereadable(project_dir .. "/bun.lockb") == 1 then
    return "bun"
  end

  -- Check if pnpm/yarn are globally available, fallback to npm
  if vim.fn.executable("pnpm") == 1 then
    return "pnpm"
  elseif vim.fn.executable("yarn") == 1 then
    return "yarn"
  end
  return "npm"
end

-- Get the run command for a package manager
local function get_run_cmd(pm, script_name)
  if pm == "npm" then
    return { "npm", "run", script_name }
  elseif pm == "yarn" then
    return { "yarn", script_name }
  elseif pm == "pnpm" then
    return { "pnpm", "run", script_name }
  elseif pm == "bun" then
    return { "bun", "run", script_name }
  end
  return { "npm", "run", script_name }
end

-- Scripts that are commonly used for development
local dev_scripts = {
  "dev", "start", "serve", "watch", "develop",
}

-- Check if a script name looks like a dev server
local function is_dev_script(name)
  for _, pattern in ipairs(dev_scripts) do
    if name == pattern or name:match("^" .. pattern .. ":") then
      return true
    end
  end
  return false
end

-- Find all package.json files in a project (for monorepo support)
local function find_package_jsons(root, max_depth)
  max_depth = max_depth or 5
  local results = {}

  local function scan(dir, depth)
    if depth > max_depth then return end
    if vim.fn.isdirectory(dir) ~= 1 then return end

    local handle = vim.uv.fs_scandir(dir)
    if not handle then return end

    while true do
      local name, type = vim.uv.fs_scandir_next(handle)
      if not name then break end

      local path = dir .. "/" .. name

      if type == "file" and name == "package.json" then
        local pkg = parse_package_json(path)
        if pkg and next(pkg.scripts) then
          pkg.path = path
          pkg.dir = dir
          table.insert(results, pkg)
        end
      elseif type == "directory" then
        -- Skip node_modules, .git, hidden dirs, dist dirs
        if not name:match("^%.")
          and name ~= "node_modules"
          and name ~= "dist"
          and name ~= "build"
          and name ~= ".next"
          and name ~= ".nuxt" then
          scan(path, depth + 1)
        end
      end
    end
  end

  scan(root, 0)
  return results
end

function M.generator(opts)
  local dir = opts.dir or vim.fn.getcwd()
  local root = find_project_root(dir)
  if not root then return {} end

  local package_jsons = find_package_jsons(root)
  if #package_jsons == 0 then return {} end

  local pm = detect_package_manager(root)
  local ret = {}
  local seen = {}

  for _, pkg in ipairs(package_jsons) do
    local is_monorepo = #package_jsons > 1
    local pkg_name = pkg.name or vim.fn.fnamemodify(pkg.dir, ":t")

    for script_name, script_cmd in pairs(pkg.scripts) do
      -- Skip postinstall, prepare, and other lifecycle scripts
      if script_name ~= "postinstall"
        and script_name ~= "preinstall"
        and script_name ~= "prepare"
        and script_name ~= "version"
        and script_name ~= "prepublishOnly" then

        local display_name = is_monorepo
          and (pkg_name .. ":" .. script_name)
          or script_name

        -- Deduplicate
        if not seen[display_name] then
          seen[display_name] = true

          local cmd = get_run_cmd(pm, script_name)
          local is_dev = is_dev_script(script_name)

          table.insert(ret, {
            name = display_name,
            builder = function(params)
              return {
                cmd = cmd,
                cwd = pkg.dir,
                name = display_name,
                components = {
                  "on_exit_set_status",
                  "on_complete_notify",
                  "service.npm",
                  {
                    "service.lifecycle",
                    auto_restart = is_dev,
                  },
                },
                metadata = {
                  service = true,
                  service_type = "npm",
                  npm = true,
                  group = is_dev and "npm:dev" or "npm",
                  project_root = root,
                  package_dir = pkg.dir,
                  package_name = pkg_name,
                  script = script_name,
                  script_cmd = script_cmd,
                  package_manager = pm,
                },
              }
            end,
            tags = {},
            params = {},
          })
        end
      end
    end
  end

  -- Sort: dev scripts first, then alphabetical
  table.sort(ret, function(a, b)
    local a_dev = is_dev_script(a.name) and 0 or 1
    local b_dev = is_dev_script(b.name) and 0 or 1
    if a_dev ~= b_dev then return a_dev < b_dev end
    return a.name < b.name
  end)

  return ret
end

return M
