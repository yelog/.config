local M = {}

local function trim_or_nil(value)
  value = value and vim.trim(value) or ""
  return value ~= "" and value or nil
end

local function fields_for(service, override)
  if service.service_type == "springboot" then
    return {
      { key = "vmArgs", label = "JVM options", value = override.vmArgs },
      { key = "springProfile", label = "Spring profile", value = override.springProfile },
      { key = "mavenProfile", label = "Maven profile", value = override.mavenProfile },
      { key = "programArgs", label = "Program arguments", value = override.programArgs },
      { key = "env", label = "Environment JSON", value = next(override.env or {}) and vim.json.encode(override.env) or nil },
    }
  end
  if service.service_type == "npm" then
    local metadata = service.metadata or {}
    local managers = require("services.launch_config").available_package_managers(
      metadata.package_dir, metadata.package_manager)
    return {
      { key = "packageManager", label = "Package manager (" .. table.concat(managers, ", ") .. ")", value = override.packageManager or metadata.package_manager },
      { key = "script", label = "Script", value = override.script or metadata.script },
      { key = "arguments", label = "Arguments", value = override.arguments },
      { key = "env", label = "Environment JSON", value = next(override.env or {}) and vim.json.encode(override.env) or nil },
    }
  end
end

local function parse(bufnr, fields)
  local values = {}
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for index, field in ipairs(fields) do
    local value = lines[index + 2] and lines[index + 2]:match("^[^=]+=(.*)$") or ""
    if field.key == "env" then
      if value ~= "" then
        local ok, decoded = pcall(vim.json.decode, value)
        if not ok or type(decoded) ~= "table" then return nil, "Environment must be a JSON object" end
        values.env = decoded
      end
    else
      values[field.key] = trim_or_nil(value)
    end
  end
  return values
end

function M.open(service, on_saved)
  local root = (service.metadata or {}).project_root
  if not root then
    vim.notify("Service configuration requires a project root", vim.log.levels.ERROR)
    return false
  end
  local launch_config = require("services.launch_config")
  local override = launch_config.get(root, service.key)
  local fields = fields_for(service, override)
  if not fields then
    vim.notify("No launch configuration is available for " .. service.service_type, vim.log.levels.WARN)
    return false
  end

  local win = Snacks.win({
    style = "float",
    border = "rounded",
    title = " Service Configuration: " .. service.name .. " ",
    fixbuf = false,
    enter = true,
    width = 0.72,
    height = math.max(0.3, math.min(0.65, (#fields + 5) / vim.o.lines)),
  })
  local lines = { "Edit values after '='. Press w to save, q to cancel.", "" }
  for _, field in ipairs(fields) do table.insert(lines, field.label .. "=" .. (field.value or "")) end
  vim.api.nvim_buf_set_lines(win.buf, 0, -1, false, lines)
  vim.bo[win.buf].modifiable = false
  vim.keymap.set("n", "w", function()
    vim.bo[win.buf].modifiable = true
    local values, err = parse(win.buf, fields)
    vim.bo[win.buf].modifiable = false
    if not values then
      vim.notify(err, vim.log.levels.ERROR)
      return
    end
    if not launch_config.set(root, service.key, values) then
      vim.notify("Failed to save .nvim/services.json", vim.log.levels.ERROR)
      return
    end
    win:close()
    vim.notify("Service configuration saved; it applies on the next start")
    if on_saved then on_saved() end
  end, { buffer = win.buf, desc = "Save service configuration" })
  vim.keymap.set("n", "q", function() win:close() end, { buffer = win.buf, desc = "Cancel service configuration" })
  vim.bo[win.buf].modifiable = true
  vim.api.nvim_win_set_cursor(win.win, { 3, #fields[1].label + 1 })
  return true
end

return M
