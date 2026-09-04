local M = {}

M.defaults = {
  cache = { persistent = false, debounce_ms = 400 },
  scan = {
    libraries = false,
    exclude = { ".git", "node_modules", "vendor", "target", "build", "dist" },
  },
  providers = {},
  request = {
    base_url_variable = "API_BASE_URL",
    fallback_base_url = "http://localhost:8080",
    confirm_unsafe_methods = true,
  },
  picker = { title = "API Query" },
}

local function merge(dst, src)
  for key, value in pairs(src or {}) do
    if type(value) == "table" and type(dst[key]) == "table" then
      merge(dst[key], value)
    else
      dst[key] = value
    end
  end
  return dst
end

function M.setup(opts)
  M.options = merge(vim.deepcopy(M.defaults), opts or {})
  return M.options
end

function M.get()
  return M.options or M.setup()
end

return M
