local M = {}

local fallback_type = {
  label = "Service",
  icon = "󰒓",
  hl = "Special",
}

local service_types = {
  springboot = {
    label = "Spring Boot",
    title = "SPRING",
    icon = "",
    hl = "String",
  },
  npm = {
    label = "npm",
    title = "NPM",
    icon = "",
    hl = "PreProc",
  },
  service = {
    label = fallback_type.label,
    title = "CUSTOM",
    icon = fallback_type.icon,
    hl = fallback_type.hl,
  },
}

local service_type_order = { "springboot", "npm", "service" }

local function normalize_keys(keys)
  local normalized = {}
  local seen = {}
  for _, key in ipairs(keys or {}) do
    if type(key) == "string" and key ~= "" and not seen[key] then
      seen[key] = true
      table.insert(normalized, key)
    end
  end
  table.sort(normalized)
  return normalized
end

function M.get_type(service_type)
  return service_types[service_type] or fallback_type
end

function M.list_types()
  local types = {}
  for _, service_type in ipairs(service_type_order) do
    table.insert(types, vim.tbl_extend("force", { service_type = service_type }, service_types[service_type]))
  end
  return types
end

function M.key_from_definition(definition)
  definition = definition or {}
  if type(definition.key) == "string" and definition.key ~= "" then return definition.key end

  local metadata = definition.metadata or {}
  local service_type = definition.service_type or metadata.service_type
  if not service_type then
    service_type = metadata.springboot and "springboot" or metadata.npm and "npm" or "service"
  end

  if service_type == "springboot" and metadata.task_key then
    return "springboot::" .. metadata.task_key
  elseif service_type == "npm" and metadata.package_dir and metadata.script then
    return "npm::" .. metadata.package_dir .. "::" .. metadata.script
  elseif type(definition.name) == "string" and definition.name ~= "" then
    return service_type .. "::" .. definition.name
  end
end

function M.filter_selected(definitions, selected_keys)
  local selected = {}
  for _, key in ipairs(selected_keys or {}) do
    selected[key] = true
  end

  local filtered = {}
  for _, definition in ipairs(definitions or {}) do
    if selected[definition.key or M.key_from_definition(definition)] then table.insert(filtered, definition) end
  end
  return filtered
end

function M.replace_category(selected_keys, definitions, service_type, replacement_keys, clear_stale)
  local available = {}
  for _, definition in ipairs(definitions or {}) do
    if definition.service_type == service_type then
      local key = definition.key or M.key_from_definition(definition)
      if key then available[key] = true end
    end
  end

  local merged = {}
  for _, key in ipairs(selected_keys or {}) do
    local key_type = key:match("^([^:]+)::")
    if not available[key] and not (clear_stale and key_type == service_type) then table.insert(merged, key) end
  end
  vim.list_extend(merged, replacement_keys or {})
  return normalize_keys(merged)
end

return M
