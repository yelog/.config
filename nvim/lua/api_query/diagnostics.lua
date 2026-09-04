local M = {}
function M.new() return { items = {} } end
function M.add(target, item, message, severity)
  local diagnostic = { file = item }
  if type(item) == "table" then for key, value in pairs(item) do diagnostic[key] = value end end
  diagnostic.message, diagnostic.severity = message or diagnostic.message or "unknown diagnostic", severity or diagnostic.severity or "warn"
  target.items = target.items or {}; target.items[#target.items + 1] = diagnostic
  return diagnostic
end
function M.merge(target, source)
  for _, item in ipairs((source or {}).items or source or {}) do M.add(target, item) end
  return target
end
function M.list(target) return target and target.items or {} end
return M
