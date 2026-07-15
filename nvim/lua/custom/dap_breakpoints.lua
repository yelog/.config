local M = {}

local schema_version = 1
local markers = {
  ".git",
  "pom.xml",
  "build.gradle",
  "build.gradle.kts",
  "package.json",
}

local options = {}
local catalogs = {}
local save_tokens = {}

local function notify(message)
  if options.notify then
    options.notify(message)
  else
    vim.notify(message, vim.log.levels.WARN, { title = "DAP breakpoints" })
  end
end

local function normalize(path)
  if type(path) ~= "string" or path == "" then return nil end
  local absolute = vim.fn.fnamemodify(path, ":p"):gsub("/$", "")
  return vim.uv.fs_realpath(absolute) or absolute
end

local function root_for_path(path)
  local normalized = normalize(path)
  if not normalized then return nil end
  local root = vim.fs.root(normalized, markers)
  if not root then root = vim.fs.dirname(normalized) end
  return normalize(root)
end

local function relative_path(root, path)
  local normalized = normalize(path)
  if not normalized then return nil end
  local prefix = root .. "/"
  if normalized:sub(1, #prefix) ~= prefix then return nil end
  return normalized:sub(#prefix + 1)
end

local function empty_catalog(root)
  return {
    version = schema_version,
    root = root,
    files = vim.empty_dict(),
  }
end

function M.storage_path(root)
  root = normalize(root)
  if not root then return nil end
  local data_dir = options.data_dir or (vim.fn.stdpath("data") .. "/dap-breakpoints")
  return data_dir .. "/" .. vim.fn.sha256(root) .. ".json"
end

local function load_catalog(root)
  if catalogs[root] ~= nil then return catalogs[root] or nil end

  local path = M.storage_path(root)
  if vim.fn.filereadable(path) ~= 1 then
    local catalog = empty_catalog(root)
    catalogs[root] = catalog
    return catalog
  end

  local ok, decoded = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
  end)
  if not ok or type(decoded) ~= "table" or decoded.version ~= schema_version
    or decoded.root ~= root or type(decoded.files) ~= "table" then
    catalogs[root] = false
    notify("Ignoring invalid breakpoint catalog: " .. path)
    return nil
  end

  catalogs[root] = decoded
  return decoded
end

local function write_catalog(root, catalog)
  local path = M.storage_path(root)
  local directory = vim.fs.dirname(path)
  if vim.fn.mkdir(directory, "p") == 0 and vim.fn.isdirectory(directory) ~= 1 then
    notify("Could not create breakpoint directory: " .. directory)
    return false
  end

  local temporary = string.format("%s.%d.tmp", path, vim.fn.getpid())
  local encoded = vim.json.encode(catalog)
  local ok, write_result = pcall(vim.fn.writefile, { encoded }, temporary)
  if not ok or write_result ~= 0 then
    notify("Could not write breakpoint catalog: " .. tostring(write_result))
    return false
  end

  local renamed, rename_error = vim.uv.fs_rename(temporary, path)
  if not renamed then
    pcall(vim.uv.fs_unlink, temporary)
    notify("Could not replace breakpoint catalog: " .. tostring(rename_error))
    return false
  end
  return true
end

local function breakpoints_for_buffer(bufnr)
  local grouped = require("dap.breakpoints").get(bufnr)
  return grouped[bufnr] or {}
end

local function serialize_breakpoint(breakpoint)
  local result = { line = breakpoint.line }
  if breakpoint.condition ~= nil then result.condition = breakpoint.condition end
  if breakpoint.hitCondition ~= nil then result.hitCondition = breakpoint.hitCondition end
  if breakpoint.logMessage ~= nil then result.logMessage = breakpoint.logMessage end
  return result
end

function M.sync_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then return false end

  local filename = vim.api.nvim_buf_get_name(bufnr)
  local root = root_for_path(filename)
  if not root then return false end
  local relative = relative_path(root, filename)
  if not relative then return false end

  local catalog = load_catalog(root)
  if not catalog then
    catalog = empty_catalog(root)
    catalogs[root] = catalog
  end
  local saved = {}
  for _, breakpoint in ipairs(breakpoints_for_buffer(bufnr)) do
    if type(breakpoint.line) == "number" then
      table.insert(saved, serialize_breakpoint(breakpoint))
    end
  end
  table.sort(saved, function(left, right) return left.line < right.line end)
  catalog.files[relative] = #saved > 0 and saved or nil
  return write_catalog(root, catalog)
end

local function schedule_sync(bufnr)
  local delay = math.max(0, options.debounce_ms or 100)
  if delay == 0 then return M.sync_buffer(bufnr) end

  local token = (save_tokens[bufnr] or 0) + 1
  save_tokens[bufnr] = token
  vim.defer_fn(function()
    if save_tokens[bufnr] ~= token then return end
    save_tokens[bufnr] = nil
    M.sync_buffer(bufnr)
  end, delay)
  return true
end

function M.restore_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then return false end

  local filename = vim.api.nvim_buf_get_name(bufnr)
  local root = root_for_path(filename)
  if not root then return false end
  local relative = relative_path(root, filename)
  if not relative then return false end

  local catalog = load_catalog(root)
  if not catalog then return false end
  local saved = catalog.files[relative]
  if type(saved) ~= "table" then return true end

  local existing_lines = {}
  for _, breakpoint in ipairs(breakpoints_for_buffer(bufnr)) do
    existing_lines[breakpoint.line] = true
  end

  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local breakpoints = require("dap.breakpoints")
  for _, breakpoint in ipairs(saved) do
    local line = tonumber(breakpoint.line)
    if line and line >= 1 and line <= line_count and not existing_lines[line] then
      breakpoints.set({
        condition = breakpoint.condition,
        hit_condition = breakpoint.hitCondition,
        log_message = breakpoint.logMessage,
      }, bufnr, line)
      existing_lines[line] = true
    end
  end
  return true
end

function M.sync_all()
  local success = true
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_buf_get_name(bufnr) ~= "" then
      local root = root_for_path(vim.api.nvim_buf_get_name(bufnr))
      local has_catalog = root and catalogs[root] ~= nil
      local has_breakpoints = next(breakpoints_for_buffer(bufnr)) ~= nil
      if has_catalog or has_breakpoints then success = M.sync_buffer(bufnr) and success end
    end
  end
  return success
end

function M.toggle()
  local bufnr = vim.api.nvim_get_current_buf()
  require("dap").toggle_breakpoint()
  schedule_sync(bufnr)
end

function M.setup(opts)
  options = vim.tbl_deep_extend("force", {
    debounce_ms = 100,
    restore_existing = true,
  }, opts or {})
  catalogs = {}
  save_tokens = {}

  local group = vim.api.nvim_create_augroup("DapBreakpointPersistence", { clear = true })
  vim.api.nvim_create_autocmd("BufReadPost", {
    group = group,
    callback = function(event) M.restore_buffer(event.buf) end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function() M.sync_all() end,
  })

  if options.restore_existing then
    vim.schedule(function()
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) then M.restore_buffer(bufnr) end
      end
    end)
  end
end

return M
