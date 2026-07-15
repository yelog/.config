local M = {}

function M.discover(opts)
  local root = (opts or {}).dir or vim.fn.getcwd()
  local definitions = {}
  for _, service in ipairs(require("custom.services").load()) do
    local restart = {
      auto = service.auto_restart == true,
      delay = service.restart_delay or 3,
      max_attempts = service.max_restarts or 3,
    }
    table.insert(definitions, {
      key = "service::" .. service.name,
      name = service.name,
      service_type = "service",
      cmd = vim.deepcopy(service.cmd),
      cwd = service.cwd or root,
      env = vim.deepcopy(service.env),
      restart = restart,
      health_check = service.health_check,
      health_interval = service.health_interval or 10,
      color_policy = "preserve",
      metadata = {
        service_type = "service",
        project_root = root,
        group = service.group or "",
      },
    })
  end
  table.sort(definitions, function(a, b) return a.name < b.name end)
  return definitions
end

return M
