local M = {}

local fallback_type = {
  label = "Service",
  icon = "󰒓",
  hl = "Special",
}

local service_types = {
  springboot = {
    module = "springboot",
    label = "Spring Boot",
    title = "SPRING",
    icon = "",
    hl = "String",
  },
  npm = {
    module = "npm",
    label = "npm",
    title = "NPM",
    icon = "",
    hl = "PreProc",
  },
  service = {
    module = "service",
    label = fallback_type.label,
    title = "CUSTOM",
    icon = fallback_type.icon,
    hl = fallback_type.hl,
  },
}

local service_type_order = { "springboot", "npm", "service" }

local function normalize_keys(keys)
  local ret = {}
  local seen = {}
  for _, key in ipairs(keys or {}) do
    if type(key) == "string" and key ~= "" and not seen[key] then
      seen[key] = true
      table.insert(ret, key)
    end
  end
  table.sort(ret)
  return ret
end

function M.get_type(service_type)
  return service_types[service_type] or fallback_type
end

function M.list_types()
  local ret = {}
  for _, service_type in ipairs(service_type_order) do
    table.insert(ret, vim.tbl_extend("force", { service_type = service_type }, service_types[service_type]))
  end
  return ret
end

function M.key_from_metadata(metadata, name)
  metadata = metadata or {}
  local service_type = metadata.service_type
  if not service_type then
    if metadata.springboot then
      service_type = "springboot"
    elseif metadata.npm then
      service_type = "npm"
    else
      service_type = "service"
    end
  end

  if service_type == "springboot" and metadata.task_key then
    return "springboot::" .. metadata.task_key
  elseif service_type == "npm" and metadata.package_dir and metadata.script then
    return "npm::" .. metadata.package_dir .. "::" .. metadata.script
  elseif name and name ~= "" then
    return service_type .. "::" .. name
  end
end

function M.discover(search_dir)
  local entries = {}
  for _, type_info in ipairs(M.list_types()) do
    local module = type_info.module
    local provider = require("overseer.template." .. module)
    for _, template in ipairs(provider.generator({ dir = search_dir }) or {}) do
      local ok, definition = pcall(template.builder, {})
      local metadata = ok and definition and definition.metadata or {}
      local service_type = metadata.service_type or module
      local key = M.key_from_metadata(metadata, template.name)
      if key then
        table.insert(entries, {
          key = key,
          module = module,
          name = template.name,
          service_type = service_type,
          template = template,
        })
      end
    end
  end
  table.sort(entries, function(a, b)
    if a.service_type ~= b.service_type then return a.service_type < b.service_type end
    return a.name < b.name
  end)
  return entries
end

function M.filter_selected(entries, selected_keys)
  local selected = {}
  for _, key in ipairs(selected_keys or {}) do
    selected[key] = true
  end

  local ret = {}
  for _, entry in ipairs(entries or {}) do
    if selected[entry.key] then table.insert(ret, entry) end
  end
  return ret
end

function M.replace_category(selected_keys, entries, service_type, replacement_keys, clear_stale)
  local available = {}
  for _, entry in ipairs(entries or {}) do
    if entry.service_type == service_type then available[entry.key] = true end
  end

  local merged = {}
  for _, key in ipairs(selected_keys or {}) do
    local key_type = key:match("^([^:]+)::")
    if not available[key] and not (clear_stale and key_type == service_type) then
      table.insert(merged, key)
    end
  end
  vim.list_extend(merged, replacement_keys or {})
  return normalize_keys(merged)
end

return M
