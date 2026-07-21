local M = {}

local installed = false

local function has_modules(project)
  return type(project) == "table" and type(project.modules) == "table" and #project.modules > 0
end

function M.build_lifecycle_command(project, lifecycle_arg, command_builder)
  command_builder = command_builder or require("maven.utils.cmd_builder")
  local command = command_builder.build_mvn_cmd(project.pom_xml_path, { lifecycle_arg })
  if not has_modules(project) then
    return command
  end

  local arguments = {}
  for _, argument in ipairs(command.args) do
    if argument ~= "-N" then
      table.insert(arguments, argument)
    end
  end

  local recursive_command = {}
  for key, value in pairs(command) do
    recursive_command[key] = value
  end
  recursive_command.args = arguments
  return recursive_command
end

function M.install()
  if installed then
    return
  end

  local project_view = require("maven.ui.projects_view")
  local console = require("maven.utils.console")
  local maven_config = require("maven.config")

  project_view._load_lifecycle_node = function(self, node, project)
    local command = M.build_lifecycle_command(project, node.extra.cmd_arg)
    local show_output = maven_config.options.console.show_lifecycle_execution
    console.execute_command(command.cmd, command.args, show_output, function(state)
      vim.schedule(function()
        node.state = state
        self._tree:render()
      end)
    end)
  end
  installed = true
end

return M
