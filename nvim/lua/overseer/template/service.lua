local overseer = require("overseer")

return {
  name = "service",
  desc = "Microservice from config",
  generator = function(opts)
    local services = require("custom.services").load()
    local ret = {}
    for _, svc in ipairs(services) do
      table.insert(ret, {
        name = svc.name,
        builder = function(params)
          return {
            cmd = svc.cmd,
            cwd = svc.cwd,
            env = svc.env,
            name = svc.name,
            components = {
              "on_exit_set_status",
              "on_complete_notify",
              {
                "service.lifecycle",
                auto_restart = svc.auto_restart or false,
                health_check = svc.health_check,
              },
            },
            metadata = {
              service = true,
              group = svc.group or "",
            },
          }
        end,
        tags = { overseer.TAG.BUILD },
        params = {},
      })
    end
    return ret
  end,
}
