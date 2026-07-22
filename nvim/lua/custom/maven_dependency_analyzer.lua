local model = require("custom.maven_dependency_model")

local M = {}
local active_view

local Analyzer = {}
Analyzer.__index = Analyzer

local function coordinate(dependency)
  return dependency.group_id .. ":" .. dependency.artifact_id
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

function Analyzer.new(root, dependencies)
  return setmetatable({
    root = root,
    dependencies = dependencies,
    graph = model.index(dependencies),
    mode = "tree",
    query = "",
    hide_test = false,
    show_size = true,
    previous_win = vim.api.nvim_get_current_win(),
  }, Analyzer)
end

function Analyzer:_options()
  return { query = self.query, hide_test = self.hide_test, conflicts_only = self.mode == "conflicts" }
end

function Analyzer:_visible_ids()
  if self.mode == "tree" then return model.visible_tree(self.graph, self:_options()) end
  return model.visible_list(self.graph, self:_options())
end

function Analyzer:_node_line(node)
  local Line = require("nui.line")
  local dependency = node.extra
  local line = Line()
  if self.mode == "tree" then
    line:append(" " .. string.rep("  ", node:get_depth() - 1))
    line:append(node:has_children() and (node:is_expanded() and "v " or "> ") or "  ", "Special")
  else
    line:append("  ")
  end
  if dependency.conflict_version then
    line:append("! ", "DiagnosticWarn")
  elseif dependency.is_duplicate then
    line:append("= ", "Comment")
  else
    line:append("- ", "Special")
  end
  line:append(coordinate(dependency), dependency.conflict_version and "DiagnosticWarn" or nil)
  line:append(":" .. dependency.version)
  if dependency.scope then line:append(" [" .. dependency.scope .. "]", "Comment") end
  if dependency.conflict_version then
    line:append(" selected=" .. dependency.version .. " omitted=" .. dependency.conflict_version, "DiagnosticWarn")
  end
  if self.show_size then
    local utils = require("maven.utils")
    line:append("  " .. (utils.humanize_size(dependency.size) or "-"), "Comment")
  end
  return line
end

function Analyzer:_tree_nodes()
  local Tree = require("nui.tree")
  local visible = {}
  for _, id in ipairs(self:_visible_ids()) do visible[id] = true end
  local function create(id)
    local children = {}
    for _, child_id in ipairs(self.graph.children[id] or {}) do
      if visible[child_id] then table.insert(children, create(child_id)) end
    end
    return Tree.Node({ id = id, extra = self.graph.by_id[id] }, children)
  end
  local nodes = {}
  for _, id in ipairs(self.graph.roots) do
    if visible[id] then table.insert(nodes, create(id)) end
  end
  return nodes
end

function Analyzer:_list_nodes()
  local Tree = require("nui.tree")
  local nodes = {}
  for _, id in ipairs(self:_visible_ids()) do
    table.insert(nodes, Tree.Node({ id = id, extra = self.graph.by_id[id] }))
  end
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
  title:append(" Maven Dependencies: " .. vim.fs.basename(self.root) .. " [" .. mode .. "]", "Title")
  title:append(suffix, "Comment")
  title:render(self.popup.bufnr, vim.api.nvim_create_namespace("maven_dependency_analyzer"), 1)
  local help = Line()
  help:append("t tree  l list  c conflicts  / search  T test  S size  r refresh  p paths  i info  q close", "Comment")
  help:render(self.popup.bufnr, vim.api.nvim_create_namespace("maven_dependency_analyzer"), 2)
  vim.api.nvim_set_option_value("modifiable", false, { buf = self.popup.bufnr })
  vim.api.nvim_set_option_value("readonly", true, { buf = self.popup.bufnr })
end

function Analyzer:render()
  local nodes = self.mode == "tree" and self:_tree_nodes() or self:_list_nodes()
  self.tree:set_nodes(nodes)
  self:_render_header()
  self.tree:render(3)
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

function Analyzer:_set_query()
  vim.ui.input({ prompt = "Maven dependency filter: ", default = self.query }, function(value)
    if value == nil then return end
    self.query = value
    self:render()
  end)
end

function Analyzer:_setup_maps()
  self.popup:map("n", { "q", "<esc>" }, function()
    self.layout:unmount()
    if vim.api.nvim_win_is_valid(self.previous_win) then vim.api.nvim_set_current_win(self.previous_win) end
  end, { nowait = true })
  self.popup:map("n", "t", function() self.mode = "tree"; self:render() end, { nowait = true })
  self.popup:map("n", "l", function() self.mode = "list"; self:render() end, { nowait = true })
  self.popup:map("n", "c", function() self.mode = "conflicts"; self:render() end, { nowait = true })
  self.popup:map("n", "/", function() self:_set_query() end, { nowait = true })
  self.popup:map("n", "T", function() self.hide_test = not self.hide_test; self:render() end, { nowait = true })
  self.popup:map("n", "S", function() self.show_size = not self.show_size; self:render() end, { nowait = true })
  self.popup:map("n", "i", function() self:_show_details() end, { nowait = true })
  self.popup:map("n", "p", function() self:_show_paths() end, { nowait = true })
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
  local root = require("custom.maven_profiles").find_project_root()
  if not root then
    vim.notify("No Maven project found for the current buffer", vim.log.levels.WARN)
    return
  end
  local ok, err = ensure_maven_plugin()
  if not ok then
    vim.notify("Unable to load maven.nvim: " .. err, vim.log.levels.ERROR)
    return
  end
  vim.notify("Loading Maven dependencies...", vim.log.levels.INFO)
  require("maven.sources").load_project_dependencies(root .. "/pom.xml", force == true, function(state, dependencies)
    if state ~= require("maven.utils").SUCCEED_STATE then return end
    if not dependencies or #dependencies == 0 then
      vim.notify("No resolved Maven dependencies found", vim.log.levels.INFO)
      return
    end
    vim.schedule(function()
      if active_view and active_view.layout then active_view.layout:unmount() end
      active_view = Analyzer.new(root, dependencies)
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
