local M = {}

local function coordinate(dependency)
  return dependency.group_id .. ":" .. dependency.artifact_id
end

local function matches(dependency, options)
  if options.hide_test and dependency.scope == "test" then return false end
  local query = string.lower(options.query or "")
  if query == "" then return true end
  local text = table.concat({
    dependency.group_id or "",
    dependency.artifact_id or "",
    dependency.version or "",
    dependency.scope or "",
  }, ":")
  return string.find(string.lower(text), query, 1, true) ~= nil
end

function M.index(dependencies)
  local graph = { by_id = {}, children = {}, roots = {}, by_coordinate = {} }
  for _, dependency in ipairs(dependencies or {}) do
    graph.by_id[dependency.id] = dependency
    local key = coordinate(dependency)
    graph.by_coordinate[key] = graph.by_coordinate[key] or {}
    table.insert(graph.by_coordinate[key], dependency.id)
    if dependency.parent_id then
      graph.children[dependency.parent_id] = graph.children[dependency.parent_id] or {}
      table.insert(graph.children[dependency.parent_id], dependency.id)
    else
      table.insert(graph.roots, dependency.id)
    end
  end
  return graph
end

function M.path_for_id(graph, id)
  local path = {}
  local dependency = graph.by_id[id]
  while dependency do
    table.insert(path, 1, dependency.id)
    dependency = dependency.parent_id and graph.by_id[dependency.parent_id] or nil
  end
  return path
end

function M.paths(graph, dependency_coordinate)
  local paths = {}
  for _, id in ipairs(graph.by_coordinate[dependency_coordinate] or {}) do
    table.insert(paths, M.path_for_id(graph, id))
  end
  return paths
end

function M.visible_tree(graph, options)
  options = options or {}
  local visible = {}
  local function visit(id)
    local dependency = graph.by_id[id]
    if options.hide_test and dependency.scope == "test" then return false end
    local child_visible = false
    for _, child_id in ipairs(graph.children[id] or {}) do
      child_visible = visit(child_id) or child_visible
    end
    local selected = matches(dependency, options) or child_visible
    if selected then visible[id] = true end
    return selected
  end
  for _, id in ipairs(graph.roots) do visit(id) end

  local result = {}
  local function collect(id)
    if not visible[id] then return end
    table.insert(result, id)
    for _, child_id in ipairs(graph.children[id] or {}) do collect(child_id) end
  end
  for _, id in ipairs(graph.roots) do collect(id) end
  return result
end

function M.visible_list(graph, options)
  options = options or {}
  local result = {}
  for key, ids in pairs(graph.by_coordinate) do
    local selected
    for _, id in ipairs(ids) do
      local dependency = graph.by_id[id]
      if matches(dependency, options) and (not options.conflicts_only or dependency.conflict_version) then
        selected = selected or id
      end
    end
    if selected then table.insert(result, { id = selected, coordinate = key }) end
  end
  table.sort(result, function(left, right) return left.coordinate < right.coordinate end)
  return vim.tbl_map(function(item) return item.id end, result)
end

return M
