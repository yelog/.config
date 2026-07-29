local M = {}

local function trim(value)
  return value:match("^%s*(.-)%s*$")
end

function M._placeholder_at(line, column)
  local start = 1
  while true do
    local open = line:find("${", start, true)
    if not open then return nil end
    local close = line:find("}", open + 2, true)
    if not close then return nil end
    if column >= open - 1 and column <= close - 1 then
      local key = line:sub(open + 2, close - 1):match("^([^}:]+)")
      return key and trim(key) or nil
    end
    start = close + 1
  end
end

function M._yaml_properties(lines)
  local properties = {}
  local stack = {}

  for row, line in ipairs(lines) do
    local indentation, raw_key = line:match("^(%s*)([^:#][^:]-)%s*:")
    if indentation and raw_key then
      local key = trim(raw_key):gsub("^['\"]", ""):gsub("['\"]$", "")
      local indent = #indentation
      while #stack > 0 and indent <= stack[#stack].indent do
        table.remove(stack)
      end
      table.insert(stack, { indent = indent, key = key })

      local colon = line:find(":", indent + 1, true)
      local value = colon and trim(line:sub(colon + 1)) or ""
      if value ~= "" and not value:match("^#") then
        local parts = vim.tbl_map(function(entry) return entry.key end, stack)
        local column = line:find(key, indent + 1, true)
        table.insert(properties, { key = table.concat(parts, "."), row = row, col = (column or 1) - 1 })
      end
    end
  end

  return properties
end

function M._properties(lines)
  local properties = {}
  for row, line in ipairs(lines) do
    local key = line:match("^%s*([^#!%s][^=:]-)%s*[=:]")
    if key then
      key = trim(key)
      local column = line:find(key, 1, true)
      table.insert(properties, { key = key, row = row, col = (column or 1) - 1 })
    end
  end
  return properties
end

local function properties_in(path, lines)
  if path:match("%.properties$") then return M._properties(lines) end
  return M._yaml_properties(lines)
end

local function add_path(paths, seen, path)
  if path ~= "" and not seen[path] then
    seen[path] = true
    table.insert(paths, path)
  end
end

function M._find_property(root, key, current_path)
  local paths, seen = {}, {}
  if current_path and vim.fn.filereadable(current_path) == 1 then add_path(paths, seen, current_path) end

  local pattern = "**/src/main/resources/{application,bootstrap}*.{yml,yaml,properties}"
  local candidates = vim.fn.globpath(root, pattern, false, true)
  table.sort(candidates)
  for _, path in ipairs(candidates) do
    add_path(paths, seen, path)
  end

  for _, path in ipairs(paths) do
    local lines
    if path == current_path and vim.api.nvim_buf_get_name(0) == path then
      lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    else
      lines = vim.fn.readfile(path)
    end
    for _, property in ipairs(properties_in(path, lines)) do
      if property.key == key then
        property.path = path
        return property
      end
    end
  end
end

function M.definition()
  local row, column = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local key = M._placeholder_at(line, column)
  if not key or key == "" then return false end

  local current_path = vim.api.nvim_buf_get_name(0)
  local root = vim.fs.root(0, { "mvnw", "gradlew", "pom.xml", "build.gradle", "build.gradle.kts", ".git" })
  if not root then return false end

  local target = M._find_property(root, key, current_path)
  if not target then return false end

  vim.cmd("edit " .. vim.fn.fnameescape(target.path))
  vim.api.nvim_win_set_cursor(0, { target.row, target.col })
  return true
end

return M
