local M = {}

local statement_tags = { select = true, insert = true, update = true, delete = true }

local function notify(message, level)
  vim.notify("MyBatis: " .. message, level or vim.log.levels.INFO)
end

local function read_file(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  return ok and lines or nil
end

local function parse_java(lines)
  local package_name
  local interface_name
  local is_mapper = false

  for _, line in ipairs(lines) do
    package_name = package_name or line:match("^%s*package%s+([%w_%.]+)%s*;")
    interface_name = interface_name or line:match("%f[%w]interface%s+([%w_]+)")
    is_mapper = is_mapper or line:match("@Mapper") ~= nil or line:match("extends%s+BaseMapper%s*<") ~= nil
  end

  if not package_name or not interface_name or not is_mapper then
    return nil
  end
  return { fqcn = package_name .. "." .. interface_name, interface_name = interface_name }
end

local function parse_xml(lines)
  for _, line in ipairs(lines) do
    local namespace = line:match('<mapper%s+namespace%s*=%s*"([^"]+)"')
      or line:match("<mapper%s+namespace%s*=%s*'([^']+)'")
    if namespace then
      return { namespace = namespace }
    end
  end
end

local function statement_at(lines, row)
  for index = math.min(row, #lines), 1, -1 do
    local line = lines[index]
    local tag, id = line:match("<%s*([%a]+)[^>]-id%s*=%s*\"([^\"]+)\"")
    if not tag then
      tag, id = line:match("<%s*([%a]+)[^>]-id%s*=%s*'([^']+)'")
    end
    if tag and statement_tags[tag] and id then
      return { id = id, row = index }
    end
    if line:match("</%s*[a-z]+%s*>") and index ~= row then
      return nil
    end
  end
end

local function method_at(lines, row)
  local line = lines[row] or ""
  local method = line:match("([%w_]+)%s*%(")
  if method and not ({ if_ = true, for_ = true, while_ = true, switch_ = true })[method .. "_"] then
    return method
  end
end

local function maven_root(path)
  local start = vim.fs.dirname(path)
  local poms = vim.fs.find("pom.xml", { upward = true, path = start })
  if #poms == 0 then
    return nil
  end
  local root = vim.fs.dirname(poms[1])
  while true do
    local parent = vim.fs.dirname(root)
    if parent == root or vim.fn.filereadable(parent .. "/pom.xml") == 0 then
      return root
    end
    root = parent
  end
end

local function rg(pattern, root, glob)
  local result = vim.fn.systemlist({ "rg", "-l", "-g", glob, pattern, root })
  return vim.v.shell_error == 0 and result or {}
end

local function xml_for_namespace(root, fqcn)
  local candidates = rg("namespace\\s*=", root, "*.xml")
  local matches = {}
  for _, path in ipairs(candidates) do
    local parsed = parse_xml(read_file(path) or {})
    if parsed and parsed.namespace == fqcn then
      table.insert(matches, path)
    end
  end
  return matches
end

local function java_for_namespace(root, fqcn)
  local package_name, class_name = fqcn:match("^(.+)%.([^.]+)$")
  if not package_name then
    return {}
  end
  local candidates = rg("package", root, class_name .. ".java")
  local matches = {}
  for _, path in ipairs(candidates) do
    local parsed = parse_java(read_file(path) or {})
    if parsed and parsed.fqcn == fqcn then
      table.insert(matches, path)
    end
  end
  return matches
end

local function statement_locations(paths, id)
  local matches = {}
  local escaped = vim.pesc(id)
  for _, path in ipairs(paths) do
    for row, line in ipairs(read_file(path) or {}) do
      if line:match("<%s*[a-z]+[^>]-id%s*=%s*[\"']" .. escaped .. "[\"']") then
        table.insert(matches, { path = path, row = row, label = path .. ":" .. row .. "  " .. id })
      end
    end
  end
  return matches
end

local function java_method_locations(paths, id)
  local escaped = vim.pesc(id)
  local matches = {}
  for _, path in ipairs(paths) do
    for row, line in ipairs(read_file(path) or {}) do
      if line:match("[%w_<>%,%s%[%]%.?]+%s+" .. escaped .. "%s*%(") then
        table.insert(matches, { path = path, row = row, label = path .. ":" .. row .. "  " .. id })
      end
    end
  end
  return matches
end

local function choose(locations, prompt)
  if #locations == 0 then
    return false
  end
  local function open(location)
    vim.cmd.edit(vim.fn.fnameescape(location.path))
    vim.api.nvim_win_set_cursor(0, { location.row, 0 })
  end
  if #locations == 1 then
    open(locations[1])
  else
    vim.ui.select(locations, {
      prompt = prompt,
      format_item = function(item) return item.label end,
    }, function(item)
      if item then open(item) end
    end)
  end
  return true
end

local function current_context()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then return nil end
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local ft = vim.bo.filetype
  local root = maven_root(path)
  if not root then return nil end

  if ft == "java" then
    local mapper = parse_java(lines)
    if not mapper then return nil end
    return { kind = "java", root = root, mapper = mapper, method = method_at(lines, row), path = path, row = row }
  end
  if ft == "xml" then
    local mapper = parse_xml(lines)
    if not mapper then return nil end
    return { kind = "xml", root = root, mapper = mapper, statement = statement_at(lines, row), path = path, row = row }
  end
end

local function mapper_target(context, want_statement)
  if context.kind == "java" then
    local xmls = xml_for_namespace(context.root, context.mapper.fqcn)
    if want_statement and context.method then
      return statement_locations(xmls, context.method)
    end
    return vim.tbl_map(function(path) return { path = path, row = 1, label = path } end, xmls)
  end
  local javas = java_for_namespace(context.root, context.mapper.namespace)
  if context.statement then
    return java_method_locations(javas, context.statement.id)
  end
  return vim.tbl_map(function(path) return { path = path, row = 1, label = path } end, javas)
end

function M.definition()
  local context = current_context()
  if not context then return false end
  local target = mapper_target(context, context.kind == "java")
  if choose(target, "MyBatis definition") then return true end
  notify(context.kind == "java" and "未找到对应 XML statement" or "未找到对应 Mapper Java", vim.log.levels.WARN)
  return true
end

function M.implementation()
  local context = current_context()
  if not context then return false end
  local target = mapper_target(context, context.kind == "java" and context.method ~= nil)
  if choose(target, "MyBatis implementation") then return true end
  notify("未找到对应的 MyBatis XML 映射", vim.log.levels.WARN)
  return true
end

function M.usages()
  local context = current_context()
  if not context then return false end
  local id = context.kind == "java" and context.method or (context.statement and context.statement.id)
  if not id then return false end
  local xmls = context.kind == "java" and xml_for_namespace(context.root, context.mapper.fqcn) or { context.path }
  local locations = statement_locations(xmls, id)
  local escaped = vim.pesc(id)
  for _, path in ipairs(xmls) do
    for row, line in ipairs(read_file(path) or {}) do
      if line:match("<include[^>]-refid%s*=%s*[\"'][^\"']*" .. escaped .. "[\"']") then
        table.insert(locations, { path = path, row = row, label = path .. ":" .. row .. "  include " .. id })
      end
    end
  end
  if choose(locations, "MyBatis usages") then return true end
  notify("未找到 MyBatis XML 用法", vim.log.levels.WARN)
  return true
end

M._parse_java = parse_java
M._parse_xml = parse_xml
M._statement_at = statement_at
M._method_at = method_at

return M
