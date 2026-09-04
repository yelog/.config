local M = {}
local config = require("api_query.config")

local function notify(message, level)
  vim.notify("api_query: " .. message, level or vim.log.levels.INFO)
end

local function index_module()
  local ok, index = pcall(require, "api_query.index")
  if not ok then
    notify("index module is not available", vim.log.levels.WARN)
    return nil
  end
  return index
end

local function endpoints(index, opts)
  if type(index.query) == "function" then return index.query(opts or {}) end
  if type(index.list) == "function" then return index.list(opts or {}) end
  if type(index.endpoints) == "function" then return index.endpoints(opts or {}) end
  if type(index.items) == "function" then return index.items(opts or {}) end
  if type(index.get) == "function" then return index.get(opts or {}) end
  return index.endpoints or index.items or {}
end

function M.setup(opts)
  local options = config.setup(opts)
  if vim.fn.exists(":ApiQuery") == 0 then
    vim.api.nvim_create_user_command("ApiQuery", function(command)
      local args = vim.split(command.args or "", "%s+", { trimempty = true })
      M.open({ method = args[1], query = table.concat(vim.list_slice(args, 2), " ") })
    end, { nargs = "*", desc = "Search source API endpoints" })
    vim.api.nvim_create_user_command("ApiQueryRefresh", function(command) M.refresh(command.bang == 1) end, { bang = true })
    vim.api.nvim_create_user_command("ApiQueryDiagnostics", M.diagnostics, {})
    vim.api.nvim_create_user_command("ApiQueryFrameworks", M.frameworks, {})
  end
  return options
end

function M.open(opts)
  local index = index_module()
  if not index then return end
  if type(index.open) == "function" then
    local result = index.open(vim.tbl_extend("force", config.get(), opts or {}))
    if type(result) == "table" then return require("api_query.picker").open(result, opts) end
  end
  return require("api_query.picker").open(endpoints(index, opts), opts)
end

function M.refresh(force)
  local index = index_module()
  if not index then return end
  if type(index.refresh) ~= "function" then return notify("index does not support refresh", vim.log.levels.WARN) end
  index.refresh(vim.tbl_extend("force", config.get(), { force = force == true }))
end

function M.diagnostics()
  local ok, diagnostics = pcall(require, "api_query.diagnostics")
  if ok and type(diagnostics.open) == "function" then return diagnostics.open() end
  if ok and type(diagnostics.list) == "function" then return require("api_query.picker").open(diagnostics.list()) end
  notify("diagnostics module is not available", vim.log.levels.WARN)
end

function M.frameworks()
  local index = index_module()
  if not index then return end
  local list = type(index.frameworks) == "function" and index.frameworks() or index.frameworks or {}
  local lines = {}
  for name, value in pairs(list) do lines[#lines + 1] = type(value) == "string" and name .. " " .. value or name end
  table.sort(lines)
  vim.notify(#lines > 0 and table.concat(lines, "\n") or "no frameworks detected")
end

return M
