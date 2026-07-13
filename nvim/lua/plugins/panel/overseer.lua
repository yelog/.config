return {
  "stevearc/overseer.nvim",
  config = function()
    local overseer = require("overseer")

    overseer.setup({
      component_aliases = {
        default = {
          "on_exit_set_status",
          "on_complete_notify",
        },
        service = {
          "on_exit_set_status",
          "on_complete_notify",
          "service.lifecycle",
        },
      },
      task_list = {
        direction = "bottom",
        min_height = 12,
        max_height = { 20, 0.3 },
        separator = "────────────────────────────────",
        render = function(task)
          local status_icons = {
            RUNNING  = "▶",
            SUCCESS  = "✖",
            FAILURE  = "✖",
            PENDING  = "◌",
            CANCELED = "■",
          }
          local status_hl = {
            RUNNING  = "DiagnosticOk",
            SUCCESS  = "DiagnosticError",
            FAILURE  = "DiagnosticError",
            PENDING  = "DiagnosticWarn",
            CANCELED = "DiagnosticHint",
          }
          local icon = status_icons[task.status] or "?"
          local hl = status_hl[task.status] or "Normal"
          return {
            {
              { " " .. icon .. "  ", hl },
              { task.name, "Normal" },
            },
          }
        end,
        sort = function(a, b)
          local order = { RUNNING = 1, PENDING = 2, CANCELED = 3, FAILURE = 4, SUCCESS = 5 }
          local sa = order[a.status] or 99
          local sb = order[b.status] or 99
          if sa ~= sb then return sa < sb end
          return a.name < b.name
        end,
        keymaps = {
          ["?"] = "keymap.show_help",
          ["<CR>"] = { "keymap.run_action", opts = { action = "smart_enter" }, desc = "Start/Open" },
          ["<C-e>"] = { "keymap.run_action", opts = { action = "edit" }, desc = "Edit task" },
          ["o"] = "keymap.open",
          ["<C-v>"] = { "keymap.open", opts = { dir = "vsplit" }, desc = "Open in vsplit" },
          ["<C-s>"] = { "keymap.open", opts = { dir = "split" }, desc = "Open in split" },
          ["<C-f>"] = { "keymap.open", opts = { dir = "float" }, desc = "Open in float" },
          ["p"] = "keymap.toggle_preview",
          ["{"] = "keymap.prev_task",
          ["}"] = "keymap.next_task",
          ["<C-k>"] = "keymap.scroll_output_up",
          ["<C-j>"] = "keymap.scroll_output_down",
          ["q"] = { "<CMD>close<CR>", desc = "Close" },
          ["s"] = { "keymap.run_action", opts = { action = "start_service" }, desc = "Start" },
          ["r"] = { "keymap.run_action", opts = { action = "restart_service" }, desc = "Restart" },
          ["S"] = { "keymap.run_action", opts = { action = "stop_service" }, desc = "Stop" },
          ["dd"] = { "keymap.run_action", opts = { action = "dispose" }, desc = "Dispose" },
        },
      },
      actions = {
        ["smart_enter"] = {
          desc = "Start or open",
          run = function(task)
            if task.status == "RUNNING" then
              overseer.run_action(task, "open")
            else
              task:reset()
              task:start()
            end
          end,
        },
        ["start_service"] = {
          desc = "Start service",
          run = function(task)
            if task.status ~= "RUNNING" then
              task:reset()
              task:start()
            end
          end,
        },
        ["restart_service"] = {
          desc = "Restart service",
          run = function(task)
            if task.status == "RUNNING" then
              task:stop()
              vim.defer_fn(function()
                task:reset()
                task:start()
              end, 300)
            else
              task:reset()
              task:start()
            end
          end,
        },
        ["stop_service"] = {
          desc = "Stop service",
          run = function(task)
            if task.status == "RUNNING" then
              task:stop()
            end
          end,
        },
        ["start_all_services"] = {
          desc = "Start all services",
          run = function()
            for _, task in ipairs(overseer.list_tasks({})) do
              if task.metadata and task.metadata.service and task.status ~= "RUNNING" then
                task:reset()
                task:start()
              end
            end
          end,
        },
        ["stop_all_services"] = {
          desc = "Stop all services",
          run = function()
            for _, task in ipairs(overseer.list_tasks({})) do
              if task.metadata and task.metadata.service and task.status == "RUNNING" then
                task:stop()
              end
            end
          end,
        },
      },
    })

    -- 打开面板前自动注册未注册的服务
    local function find_project_root()
      local buf_dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p:h")
      local dir = buf_dir
      local last_pom = nil
      while dir and dir ~= "/" and dir ~= vim.fn.expand("~") do
        if vim.fn.isdirectory(dir .. "/.git") == 1 then
          return dir
        end
        if vim.fn.filereadable(dir .. "/pom.xml") == 1 then
          last_pom = dir
        end
        dir = vim.fn.fnamemodify(dir, ":h")
      end
      return last_pom or vim.fn.getcwd()
    end

    -- 打开面板前自动注册未注册的服务
    local function ensure_services()
      local template = require("overseer.template")
      local search_dir = find_project_root()
      template.list({ dir = search_dir }, function(templates)
        if #templates == 0 then return end
        vim.schedule(function()
          local existing = {}
          for _, task in ipairs(overseer.list_tasks({})) do
            existing[task.name] = true
          end
          for _, tmpl in ipairs(templates) do
            if not existing[tmpl.name] then
              overseer.run_task({ name = tmpl.name }, function(task)
                if task then task:stop() end
              end)
            end
          end
        end)
      end)
    end

    -- 覆盖命令：打开前先注册服务
    vim.api.nvim_create_user_command("OverseerToggle", function()
      ensure_services()
      vim.defer_fn(function() overseer.toggle() end, 200)
    end, { desc = "Toggle overseer with auto-discovery", nargs = "?", bang = true })

    vim.api.nvim_create_user_command("OverseerOpen", function()
      ensure_services()
      vim.defer_fn(function() overseer.open() end, 200)
    end, { desc = "Open overseer with auto-discovery", nargs = "?", bang = true })
  end,
}
