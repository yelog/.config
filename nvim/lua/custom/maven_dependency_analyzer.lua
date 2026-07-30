local model = require("custom.maven_dependency_model")

local M = {}
local active_view

local Analyzer = {}
Analyzer.__index = Analyzer

local function coordinate(dependency)
  return dependency.group_id .. ":" .. dependency.artifact_id
end

local function pom_artifact_id(pom_path)
  local ok, lines = pcall(vim.fn.readfile, pom_path)
  if ok then
    local in_parent = false
    for _, line in ipairs(lines) do
      if line:find("<parent>", 1, true) then in_parent = true end
      if not in_parent then
        local artifact_id = line:match("<artifactId>%s*([^<]+)%s*</artifactId>")
        if artifact_id then return vim.trim(artifact_id) end
      end
      if line:find("</parent>", 1, true) then in_parent = false end
    end
  end
  return vim.fs.basename(vim.fs.dirname(pom_path))
end

local function ensure_maven_plugin()
  if pcall(require, "maven.sources") then return true end
  local ok, lazy = pcall(require, "lazy")
  if not ok then return false, "lazy.nvim is unavailable" end
  local loaded, err = pcall(lazy.load, { plugins = { "maven.nvim" } })
  if not loaded then return false, tostring(err) end
  if not pcall(require, "maven.sources") then return false, "maven.nvim did not load" end
  return true
end

local function popup_lines(title, lines)
  local Popup = require("nui.popup")
  local popup = Popup({
    enter = true,
    relative = "editor",
    position = "50%",
    size = { width = "70%", height = math.min(math.max(#lines + 2, 6), 24) },
    border = { style = "rounded", text = { top = " " .. title .. " ", top_align = "center" } },
    buf_options = { buftype = "nofile", swapfile = false },
  })
  popup:mount()
  vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = popup.bufnr })
  popup:map("n", { "q", "<esc>" }, function() popup:unmount() end, { nowait = true })
end

function Analyzer.new(pom_path, dependencies)
  return setmetatable({
    pom_path = pom_path,
    root = vim.fs.dirname(pom_path),
    module_name = pom_artifact_id(pom_path),
    dependencies = dependencies,
    graph = model.index(dependencies),
    mode = "tree",
    query = "",
    hide_test = false,
    show_size = true,
    show_group_id = false,
    sort_by_size = false,
    previous_win = vim.api.nvim_get_current_win(),
  }, Analyzer)
end

function Analyzer:_options()
  return { query = self.query, hide_test = self.hide_test, conflicts_only = self.mode == "conflicts" }
end

function Analyzer:_visible_ids()
  local ids = self.mode == "tree" and model.visible_tree(self.graph, self:_options())
    or model.visible_list(self.graph, self:_options())
  return model.ordered_ids(self.graph, ids, { sort_by_size = self.sort_by_size })
end

function Analyzer:_ordered_ids(ids)
  return model.ordered_ids(self.graph, ids, { sort_by_size = self.sort_by_size })
end

function Analyzer:_matching_ids()
  if self.query == "" then return {} end
  return model.matching_ids(self.graph, self:_options())
end

function Analyzer:_node_line(node)
  local Line = require("nui.line")
  if node.empty then
    local line = Line()
    line:append('  No dependencies match "' .. self.query .. '" in ' .. self.module_name, "Comment")
    return line
  end
  local dependency = node.extra
  local is_match = self.matching_ids[node.id]
  local line = Line()
  if self.mode == "tree" then
    line:append(" " .. string.rep("  ", node:get_depth() - 1))
    line:append(node:has_children() and (node:is_expanded() and "v " or "> ") or "  ", "Special")
  else
    line:append("  ")
  end
  if not dependency.parent_id then
    line:append("D ", "String")
  elseif dependency.conflict_version then
    line:append("! ", "DiagnosticWarn")
  elseif dependency.is_duplicate then
    line:append("= ", "DiagnosticHint")
  else
    line:append("· ", "Comment")
  end
  line:append(dependency.artifact_id, is_match and "Search" or dependency.conflict_version and "DiagnosticWarn" or "Identifier")
  if self.show_group_id then line:append("  " .. dependency.group_id, "Comment") end
  line:append("  " .. dependency.version, "Constant")
  if dependency.scope then
    local scope_highlight = dependency.scope == "test" and "DiagnosticInfo"
      or dependency.scope == "provided" and "DiagnosticHint" or "Type"
    line:append(" [" .. dependency.scope .. "]", scope_highlight)
  end
  if dependency.conflict_version then
    line:append(" selected=" .. dependency.version .. " omitted=" .. dependency.conflict_version, "DiagnosticWarn")
  end
  if self.show_size then
    local utils = require("maven.utils")
    line:append(string.format("  %9s", utils.humanize_size(dependency.size) or "-"), "Comment")
  end
  return line
end

function Analyzer:_tree_nodes()
  local Tree = require("nui.tree")
  local visible = {}
  for _, id in ipairs(self:_visible_ids()) do visible[id] = true end
  local function create(id)
    local children = {}
    for _, child_id in ipairs(self:_ordered_ids(self.graph.children[id] or {})) do
      if visible[child_id] then table.insert(children, create(child_id)) end
    end
    return Tree.Node({ id = id, extra = self.graph.by_id[id] }, children)
  end
  local nodes = {}
  for _, id in ipairs(self:_ordered_ids(self.graph.roots)) do
    if visible[id] then table.insert(nodes, create(id)) end
  end
  if #nodes == 0 and self.query ~= "" then table.insert(nodes, Tree.Node({ empty = true })) end
  return nodes
end

function Analyzer:_list_nodes()
  local Tree = require("nui.tree")
  local nodes = {}
  for _, id in ipairs(self:_visible_ids()) do
    table.insert(nodes, Tree.Node({ id = id, extra = self.graph.by_id[id] }))
  end
  if #nodes == 0 and self.query ~= "" then table.insert(nodes, Tree.Node({ empty = true })) end
  return nodes
end

function Analyzer:_render_header()
  local Line = require("nui.line")
  local mode = self.mode == "tree" and "Tree" or self.mode == "list" and "List" or "Conflicts"
  local filters = {}
  if self.query ~= "" then table.insert(filters, "search=" .. self.query) end
  if self.hide_test then table.insert(filters, "test hidden") end
  local suffix = #filters > 0 and " | " .. table.concat(filters, ", ") or ""
  vim.api.nvim_set_option_value("modifiable", true, { buf = self.popup.bufnr })
  vim.api.nvim_set_option_value("readonly", false, { buf = self.popup.bufnr })
  local title = Line()
  title:append(" Maven Dependencies  /  " .. self.module_name .. " ", "Title")
  title:append("[" .. mode .. "]", "Visual")
  title:append(suffix, "Comment")
  title:render(self.popup.bufnr, vim.api.nvim_create_namespace("maven_dependency_analyzer"), 1)
  local context = Line()
  context:append(" pom: " .. vim.fn.fnamemodify(self.pom_path, ":."), "Comment")
  context:render(self.popup.bufnr, vim.api.nvim_create_namespace("maven_dependency_analyzer"), 2)
  local summary = model.summary(self.graph)
  local utils = require("maven.utils")
  local overview = Line()
  overview:append(string.format(" %d direct", summary.direct), "String")
  overview:append(string.format("  ·  %d resolved", summary.resolved), "Identifier")
  overview:append(string.format("  ·  %d conflicts", summary.conflicts), summary.conflicts > 0 and "DiagnosticWarn" or "Comment")
  overview:append("  ·  " .. (utils.humanize_size(summary.size) or summary.size .. " B"), "Comment")
  overview:render(self.popup.bufnr, vim.api.nvim_create_namespace("maven_dependency_analyzer"), 3)
  local controls = Line()
  local function control(key, label, active)
    controls:append(" [" .. key .. " " .. label .. "]", active and "Visual" or "Comment")
  end
  control("t", "tree", self.mode == "tree")
  control("l", "list", self.mode == "list")
  control("c", "conflicts", self.mode == "conflicts")
  control("/", "filter", self.query ~= "")
  control("g", "group", self.show_group_id)
  control("T", "tests", self.hide_test)
  control("s", "sort", self.sort_by_size)
  control("S", "size", self.show_size)
  controls:append("  r refresh  p paths  o pom  i info  q close", "Comment")
  controls:render(self.popup.bufnr, vim.api.nvim_create_namespace("maven_dependency_analyzer"), 4)
  vim.api.nvim_set_option_value("modifiable", false, { buf = self.popup.bufnr })
  vim.api.nvim_set_option_value("readonly", true, { buf = self.popup.bufnr })
end

function Analyzer:_expand_visible_tree()
  local function visit(node)
    if not node:has_children() then return end
    node:expand()
    for _, child in ipairs(self.tree:get_nodes(node._id)) do visit(child) end
  end
  for _, node in ipairs(self.tree:get_nodes()) do visit(node) end
end

function Analyzer:render(expand_tree)
  self.matching_ids = self:_matching_ids()
  local nodes = self.mode == "tree" and self:_tree_nodes() or self:_list_nodes()
  self.tree:set_nodes(nodes)
  if expand_tree and self.mode == "tree" then self:_expand_visible_tree() end
  self:_render_header()
  self.tree:render(5)
end

function Analyzer:_selected()
  local node = self.tree:get_node()
  return node and node.extra or nil
end

function Analyzer:_show_details()
  local dependency = self:_selected()
  if not dependency then return end
  popup_lines("Dependency Details", {
    "Group:    " .. dependency.group_id,
    "Artifact: " .. dependency.artifact_id,
    "Version:  " .. dependency.version,
    "Scope:    " .. (dependency.scope or "-"),
    "Size:     " .. (require("maven.utils").humanize_size(dependency.size) or "-"),
    "Conflict: " .. (dependency.conflict_version or "none"),
    "Duplicate: " .. tostring(dependency.is_duplicate == true),
  })
end

function Analyzer:_show_paths()
  local dependency = self:_selected()
  if not dependency then return end
  local lines = {}
  for _, path in ipairs(model.paths(self.graph, coordinate(dependency))) do
    local parts = {}
    for _, id in ipairs(path) do
      local item = self.graph.by_id[id]
      table.insert(parts, coordinate(item) .. ":" .. item.version)
    end
    table.insert(lines, table.concat(parts, " -> "))
  end
  popup_lines("Dependency Paths", #lines > 0 and lines or { "No paths found" })
end

function Analyzer:_open_pom_declaration()
  local dependency = self:_selected()
  if not dependency then return end
  if dependency.parent_id then
    vim.notify("Transitive dependency: use p to inspect its path", vim.log.levels.INFO)
    return
  end
  if vim.api.nvim_win_is_valid(self.previous_win) then vim.api.nvim_set_current_win(self.previous_win) end
  self.layout:unmount()
  vim.cmd("edit " .. vim.fn.fnameescape(self.pom_path))
  vim.fn.search("\\V<artifactId>" .. vim.pesc(dependency.artifact_id) .. "</artifactId>")
end

function Analyzer:_set_query()
  vim.ui.input({ prompt = "Maven dependency filter: ", default = self.query }, function(value)
    if value == nil then return end
    self.query = value
    self:render(value ~= "")
    if vim.api.nvim_win_is_valid(self.popup.winid) then vim.api.nvim_set_current_win(self.popup.winid) end
  end)
end

function Analyzer:_setup_maps()
  self.popup:map("n", { "q", "<esc>" }, function()
    self.layout:unmount()
    if vim.api.nvim_win_is_valid(self.previous_win) then vim.api.nvim_set_current_win(self.previous_win) end
  end, { nowait = true })
  self.popup:map("n", "t", function() self.mode = "tree"; self:render(self.query ~= "") end, { nowait = true })
  self.popup:map("n", "l", function() self.mode = "list"; self:render() end, { nowait = true })
  self.popup:map("n", "c", function() self.mode = "conflicts"; self:render() end, { nowait = true })
  self.popup:map("n", "/", function() self:_set_query() end, { nowait = true })
  self.popup:map("n", "T", function() self.hide_test = not self.hide_test; self:render(self.query ~= "") end, { nowait = true })
  self.popup:map("n", "g", function() self.show_group_id = not self.show_group_id; self:render(self.query ~= "") end, { nowait = true })
  self.popup:map("n", "s", function() self.sort_by_size = not self.sort_by_size; self:render(self.query ~= "") end, { nowait = true })
  self.popup:map("n", "S", function() self.show_size = not self.show_size; self:render(self.query ~= "") end, { nowait = true })
  self.popup:map("n", "i", function() self:_show_details() end, { nowait = true })
  self.popup:map("n", "p", function() self:_show_paths() end, { nowait = true })
  self.popup:map("n", "o", function() self:_open_pom_declaration() end, { nowait = true })
  self.popup:map("n", "r", function() M.open(true) end, { nowait = true })
  self.popup:map("n", "<enter>", function()
    if self.mode ~= "tree" then return end
    local node = self.tree:get_node()
    if node and node:has_children() then
      if node:is_expanded() then node:collapse() else node:expand() end
      self.tree:render()
    end
  end, { nowait = true })
end

function Analyzer:mount()
  local Popup = require("nui.popup")
  local Tree = require("nui.tree")
  self.popup = Popup({
    enter = true,
    relative = "editor",
    position = "50%",
    size = { width = "90%", height = "80%" },
    border = { style = "rounded" },
    buf_options = { buftype = "nofile", swapfile = false, filetype = "maven_dependencies" },
    win_options = { cursorline = true, number = false, relativenumber = false, signcolumn = "no" },
  })
  self.tree = Tree({
    ns_id = vim.api.nvim_create_namespace("maven_dependency_analyzer"),
    bufnr = self.popup.bufnr,
    prepare_node = function(node) return self:_node_line(node) end,
  })
  self.layout = self.popup
  self.popup:mount()
  self:_setup_maps()
  self:render()
end

function M.open(force)
  local pom_path = require("custom.maven_profiles").find_nearest_pom()
  if not pom_path then
    vim.notify("No Maven pom.xml found for the current buffer", vim.log.levels.WARN)
    return
  end
  local ok, err = ensure_maven_plugin()
  if not ok then
    vim.notify("Unable to load maven.nvim: " .. err, vim.log.levels.ERROR)
    return
  end
  vim.notify("Loading Maven dependencies...", vim.log.levels.INFO)
  require("maven.sources").load_project_dependencies(pom_path, force == true, function(state, dependencies)
    if state ~= require("maven.utils").SUCCEED_STATE then return end
    if not dependencies or #dependencies == 0 then
      vim.notify("No resolved Maven dependencies found", vim.log.levels.INFO)
      return
    end
    vim.schedule(function()
      if active_view and active_view.layout then active_view.layout:unmount() end
      active_view = Analyzer.new(pom_path, dependencies)
      active_view:mount()
    end)
  end)
end

function M.setup()
  vim.api.nvim_create_user_command("MavenDependencies", function() M.open() end, {
    desc = "Analyze Maven dependencies for the current project",
    force = true,
  })
end

return M
