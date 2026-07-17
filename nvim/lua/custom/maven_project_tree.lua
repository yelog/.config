local M = {}

local installed = false

local function pom_path(project)
  return vim.fs.normalize(project.pom_xml_path)
end

local function project_sort(left, right)
  local left_name = string.lower(left.name or "")
  local right_name = string.lower(right.name or "")
  if left_name == right_name then
    return pom_path(left) < pom_path(right)
  end
  return left_name < right_name
end

local function sort_projects(projects)
  table.sort(projects, project_sort)
  for _, project in ipairs(projects) do
    sort_projects(project.modules)
  end
end

local function collect_projects(projects)
  local all_projects = {}
  local projects_by_pom = {}

  local function collect(items)
    for _, project in ipairs(items) do
      local path = pom_path(project)
      if not projects_by_pom[path] then
        projects_by_pom[path] = project
        table.insert(all_projects, project)
        collect(project.modules)
      end
    end
  end

  collect(projects)
  return all_projects, projects_by_pom
end

local function reaches_path(graph, from, target, visited)
  if from == target then
    return true
  end
  if visited[from] then
    return false
  end

  visited[from] = true
  for _, child in ipairs(graph[from] or {}) do
    if reaches_path(graph, child, target, visited) then
      return true
    end
  end
  return false
end

local function module_pom_path(project, module_path, projects_by_pom)
  local direct_path = vim.fs.normalize(vim.fs.joinpath(project.root_path, module_path))
  if projects_by_pom[direct_path] then
    return direct_path
  end
  return vim.fs.normalize(vim.fs.joinpath(direct_path, "pom.xml"))
end

local function default_parse_file(path)
  return require("maven.parsers.pom_xml_parser").parse_file(path)
end

function M.rebuild(projects, parse_file)
  parse_file = parse_file or default_parse_file

  local all_projects, projects_by_pom = collect_projects(projects)
  for _, project in ipairs(all_projects) do
    project.modules = {}
  end

  local candidates = {}
  for _, project in ipairs(all_projects) do
    local parent_pom = pom_path(project)
    local parsed = parse_file(project.pom_xml_path)
    local children = {}
    local seen_children = {}
    for _, module_path in ipairs(parsed.module_paths or {}) do
      if type(module_path) == "string" then
        local child_pom = module_pom_path(project, module_path, projects_by_pom)
        if projects_by_pom[child_pom] and not seen_children[child_pom] then
          seen_children[child_pom] = true
          table.insert(children, child_pom)
        end
      end
    end
    candidates[parent_pom] = children
  end

  table.sort(all_projects, function(left, right)
    return pom_path(left) < pom_path(right)
  end)

  local attached = {}
  for _, parent in ipairs(all_projects) do
    local parent_pom = pom_path(parent)
    for _, child_pom in ipairs(candidates[parent_pom]) do
      if not attached[child_pom] and not reaches_path(candidates, child_pom, parent_pom, {}) then
        table.insert(parent.modules, projects_by_pom[child_pom])
        attached[child_pom] = true
      end
    end
  end

  local roots = {}
  for _, project in ipairs(all_projects) do
    if not attached[pom_path(project)] then
      table.insert(roots, project)
    end
  end
  sort_projects(roots)
  return roots
end

function M.install()
  if installed then
    return
  end

  local sources = require("maven.sources")
  local upstream_scan_projects = sources.scan_projects
  sources.scan_projects = function(base_path, callback)
    return upstream_scan_projects(base_path, function(projects)
      callback(M.rebuild(projects))
    end)
  end
  installed = true
end

return M
