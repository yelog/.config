local catalog = require("services.catalog")

local M = {}

local providers = {
  require("services.providers.springboot"),
  require("services.providers.npm"),
  require("services.providers.custom"),
}

function M.discover(root)
  local definitions = {}
  for _, provider in ipairs(providers) do
    for _, definition in ipairs(provider.discover({ dir = root }) or {}) do
      definition.key = catalog.key_from_definition(definition)
      if definition.key then table.insert(definitions, definition) end
    end
  end
  table.sort(definitions, function(a, b)
    if a.service_type ~= b.service_type then return a.service_type < b.service_type end
    return a.name < b.name
  end)
  return definitions
end

return M
