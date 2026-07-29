local M = {}

local function path(root)
  return root and root ~= "" and (root .. "/.nvim/services.json") or nil
end

local function read(root)
  local filepath = path(root)
  if not filepath or vim.fn.filereadable(filepath) ~= 1 then return {} end
  local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(filepath), "\n"))
  if not ok or type(decoded) ~= "table" then return {} end
  return decoded
end

local function object(value)
  return type(value) == "table" and value or {}
end

function M.get(root, key)
  local config = read(root)
  local defaults = object(config.defaults)
  local service = object(object(config.services)[key])
  return vim.tbl_deep_extend("force", {}, defaults, service)
end

function M.set(root, key, override)
  if type(root) ~= "string" or root == "" or type(key) ~= "string" or key == "" or type(override) ~= "table" then
    return false
  end
  local config = read(root)
  config.services = object(config.services)
  config.services[key] = override
  local dir = root .. "/.nvim"
  if vim.fn.mkdir(dir, "p") == 0 and vim.fn.isdirectory(dir) ~= 1 then return false end
  local encoded = vim.json.encode(config)
  return vim.fn.writefile({ encoded }, dir .. "/services.json") == 0
end

function M.available_package_managers(package_dir, detected)
  local managers, seen = {}, {}
  local function add(name)
    if name and not seen[name] then
      seen[name] = true
      table.insert(managers, name)
    end
  end
  add(detected)
  for _, name in ipairs({ "pnpm", "yarn", "npm", "bun" }) do
    if vim.fn.executable(name) == 1 then add(name) end
  end
  return managers
end

return M
