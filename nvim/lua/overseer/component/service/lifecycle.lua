return {
  desc = "Service lifecycle management (health check, auto-restart)",
  params = {
    health_check = {
      desc = "Command to run as health check",
      type = "string",
      optional = true,
    },
    health_interval = {
      desc = "Health check interval in seconds",
      type = "number",
      default = 10,
    },
    auto_restart = {
      desc = "Auto restart on failure",
      type = "boolean",
      default = false,
    },
    restart_delay = {
      desc = "Delay before restart in seconds",
      type = "number",
      default = 3,
    },
    max_restarts = {
      desc = "Max consecutive restart attempts (0 = unlimited)",
      type = "number",
      default = 3,
    },
    output_limit = {
      desc = "Maximum terminal scrollback lines",
      type = "number",
      default = 10000,
    },
  },
  editable = true,
  serializable = true,
  constructor = function(params)
    local timer = nil
    local restart_count = 0

    return {
      on_init = function(self, task)
        task.metadata.service = true
        task.metadata.restart_count = 0
      end,

      on_start = function(self, task)
        restart_count = 0
        task.metadata.started_at = os.time()

        local bufnr = task:get_bufnr()
        if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
          local function apply_output_limit()
            if vim.api.nvim_buf_is_valid(bufnr) then
              vim.bo[bufnr].scrollback = params.output_limit or 10000
            end
          end
          apply_output_limit()
          if vim.bo[bufnr].buftype ~= "terminal" then
            vim.api.nvim_create_autocmd("TermOpen", {
              buffer = bufnr,
              once = true,
              callback = function() vim.schedule(apply_output_limit) end,
            })
          end
        end

        if params.health_check and params.health_check ~= "" then
          timer = vim.loop.new_timer()
          local interval_ms = (params.health_interval or 10) * 1000
          timer:start(interval_ms, interval_ms, vim.schedule_wrap(function()
            vim.system(
              vim.split(params.health_check, " "),
              { cwd = task.cwd },
              function(obj)
                if obj.code ~= 0 then
                  vim.schedule(function()
                    vim.notify(
                      "[Service] " .. task.name .. " health check failed (exit " .. obj.code .. ")",
                      vim.log.levels.WARN
                    )
                  end)
                end
              end
            )
          end))
        end
      end,

      on_exit = function(self, task, code)
        if timer then
          timer:stop()
          timer:close()
          timer = nil
        end

        if params.auto_restart and code ~= 0 then
          restart_count = restart_count + 1
          task.metadata.restart_count = restart_count

          if params.max_restarts > 0 and restart_count > params.max_restarts then
            vim.schedule(function()
              vim.notify(
                "[Service] " .. task.name .. " exceeded max restarts (" .. params.max_restarts .. ")",
                vim.log.levels.ERROR
              )
            end)
            return
          end

          local delay = params.restart_delay or 3
          vim.schedule(function()
            vim.notify(
              "[Service] " .. task.name .. " restarting in " .. delay .. "s (attempt " .. restart_count .. ")",
              vim.log.levels.INFO
            )
          end)

          vim.defer_fn(function()
            if task then
              task:start()
            end
          end, delay * 1000)
        end
      end,

      on_dispose = function(self, task)
        if timer then
          timer:stop()
          timer:close()
          timer = nil
        end
      end,
    }
  end,
}
