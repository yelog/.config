local M = { registry = {} }

local builtins = {
  "api_query.providers.java.spring", "api_query.providers.java.jaxrs",
  "api_query.providers.python.fastapi", "api_query.providers.python.flask", "api_query.providers.python.django",
  "api_query.providers.go.net_http", "api_query.providers.go.gin", "api_query.providers.go.chi",
  "api_query.providers.node.express", "api_query.providers.node.fastify", "api_query.providers.node.nest",
}

function M.register(provider)
  assert(type(provider) == "table" and type(provider.id) == "string", "provider.id is required")
  M.registry[provider.id] = provider
  return provider
end
function M.get(id) return M.registry[id] end
function M.list()
  local result = {}
  for _, provider in pairs(M.registry) do result[#result + 1] = provider end
  table.sort(result, function(a, b) return a.id < b.id end)
  return result
end
function M.load(opts)
  opts = opts or {}
  for _, name in ipairs(opts.modules or builtins) do
    local ok, provider = pcall(require, name)
    if ok and type(provider) == "table" then
      if not provider.id then provider.id = name:match("([%w_]+)$") end
      if provider.id then M.register(provider) end
    end
  end
  for _, provider in ipairs(opts.providers or {}) do M.register(provider) end
  return M.list()
end
M.load()
return M
