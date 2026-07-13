return {
  "stevearc/overseer.nvim",
  config = function()
    local overseer = require("overseer")
    local service_state = require("overseer.service_state")
    local roots_by_tab = {}

    local function find_project_root(source)
      local dir = source or vim.api.nvim_buf_get_name(0)
      if dir == "" then dir = vim.fn.getcwd() end
      if vim.fn.isdirectory(dir) ~= 1 then
        dir = vim.fn.fnamemodify(dir, ":p:h")
      end

      local last_build_root = nil
      while dir and dir ~= "" do
        if vim.fn.isdirectory(dir .. "/.git") == 1 then return dir end
        if vim.fn.filereadable(dir .. "/pom.xml") == 1
          or vim.fn.filereadable(dir .. "/build.gradle") == 1
          or vim.fn.filereadable(dir .. "/build.gradle.kts") == 1 then
          last_build_root = dir
        end

        local parent = vim.fn.fnamemodify(dir, ":h")
        if parent == dir then break end
        dir = parent
      end
      return last_build_root or vim.fn.getcwd()
    end

    local function spring_task(task)
      return task.metadata and task.metadata.springboot == true
    end

    local function refresh_winbar()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == "OverseerList" then
          local tab = vim.api.nvim_win_get_tabpage(win)
          local root = roots_by_tab[tab]
          local profile = root and service_state.get_profile(root) or nil
          profile = (profile or "default"):gsub("%%", "%%%%")
          vim.wo[win].winbar = table.concat({
            "%#Title# SPRING SERVICES %*",
            "%#DiagnosticInfo#◆ profile: " .. profile .. "%*",
            "%#Comment#  [p switch] %*",
          })
        end
      end
    end

    local function select_profile()
      local tab = vim.api.nvim_get_current_tabpage()
      local root = roots_by_tab[tab] or find_project_root()
      roots_by_tab[tab] = root
      local profiles = service_state.parse_maven_profiles(root)
      if #profiles == 0 then
        vim.notify("No Maven profiles found in " .. root .. "/pom.xml", vim.log.levels.WARN)
        return
      end

      local choices = { { label = "[no profile]", profile = nil } }
      for _, profile in ipairs(profiles) do
        table.insert(choices, { label = profile, profile = profile })
      end
      local current = service_state.get_profile(root)
      vim.ui.select(choices, {
        prompt = "Spring profile",
        format_item = function(item)
          return (item.profile == current and "● " or "  ") .. item.label
        end,
      }, function(choice)
        if not choice then return end

        local profile = choice.profile
        if not service_state.set_profile(root, profile) then
          vim.notify("Failed to persist Spring profile", vim.log.levels.ERROR)
          return
        end

        refresh_winbar()

        local restarted = 0
        for _, task in ipairs(overseer.list_tasks({})) do
          if spring_task(task)
            and task.metadata.project_root == root
            and task.status == "RUNNING" then
            if task:restart(true) then restarted = restarted + 1 end
          end
        end

        local label = profile or "default"
        local restart_label = restarted > 0 and string.format(" · restarted %d service(s)", restarted) or ""
        vim.notify(string.format("Spring profile: %s%s", label, restart_label))
      end)
    end

    local function task_visual(task)
      if task.status == "FAILURE" then
        return "×", "DiagnosticError", "failed", "DiagnosticError"
      elseif task.status == "RUNNING" and task.metadata and task.metadata.ready then
        local detail = task.metadata.port and (":" .. task.metadata.port) or "ready"
        return "●", "DiagnosticOk", detail, "DiagnosticInfo"
      elseif task.status == "RUNNING" then
        return "◐", "DiagnosticWarn", "starting", "DiagnosticWarn"
      elseif task.status == "PENDING" then
        return "○", "Comment", "stopped", "Comment"
      elseif task.status == "CANCELED" then
        return "■", "DiagnosticHint", "stopped", "Comment"
      elseif task.status == "SUCCESS" then
        return "✓", "DiagnosticInfo", "finished", "Comment"
      end
      return "?", "Comment", task.status:lower(), "Comment"
    end

    local function sort_rank(task)
      if task.status == "FAILURE" then return 1 end
      if task.status == "RUNNING" and task.metadata and task.metadata.ready then return 2 end
      if task.status == "RUNNING" then return 3 end
      if task.status == "PENDING" then return 4 end
      if task.status == "CANCELED" then return 5 end
      if task.status == "SUCCESS" then return 6 end
      return 99
    end

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
          local icon, icon_hl, detail, detail_hl = task_visual(task)
          return {
            {
              { " " .. icon .. "  ", icon_hl },
              { task.name, "Normal" },
              { "  " .. detail, detail_hl },
            },
          }
        end,
        sort = function(a, b)
          local rank_a = sort_rank(a)
          local rank_b = sort_rank(b)
          if rank_a ~= rank_b then return rank_a < rank_b end
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
          ["p"] = { select_profile, desc = "Select Spring profile" },
          ["gp"] = "keymap.toggle_preview",
          ["u"] = { "keymap.run_action", opts = { action = "open_service_url" }, desc = "Open service URL" },
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
            task:restart(true)
          end,
        },
        ["stop_service"] = {
          desc = "Stop service",
          run = function(task)
            if task.status == "RUNNING" then task:stop() end
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
        ["open_service_url"] = {
          desc = "Open service URL",
          condition = function(task)
            return spring_task(task)
          end,
          run = function(task)
            local url = task.metadata and task.metadata.ready and task.metadata.url or nil
            if not url then
              vim.notify("Service is not ready or no application port was detected", vim.log.levels.WARN)
              return
            end

            local _, err = vim.ui.open(url)
            if err then vim.notify("Failed to open " .. url .. ": " .. err, vim.log.levels.ERROR) end
          end,
        },
      },
    })

    local panel_group = vim.api.nvim_create_augroup("overseer_services_panel", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
      group = panel_group,
      pattern = "OverseerList",
      callback = function() vim.schedule(refresh_winbar) end,
    })
    vim.api.nvim_create_autocmd("User", {
      group = panel_group,
      pattern = "OverseerListUpdate",
      callback = refresh_winbar,
    })

    local function ensure_services(search_dir, callback)
      local template = require("overseer.template")
      local templates = {}
      for _, module in ipairs({ "springboot", "service" }) do
        local provider = require("overseer.template." .. module)
        local generated = provider.generator({ dir = search_dir }) or {}
        for _, tmpl in ipairs(generated) do
          tmpl.module = module
          table.insert(templates, tmpl)
        end
      end

      local existing = {}
      for _, task in ipairs(overseer.list_tasks({})) do
        if spring_task(task) and task.metadata.task_key then
          existing["springboot::" .. task.metadata.task_key] = true
        elseif task.metadata and task.metadata.service then
          existing["service::" .. task.name] = true
        end
      end

      local pending = {}
      for _, tmpl in ipairs(templates) do
        local service_key = "service::" .. tmpl.name
        if tmpl.module == "springboot" or not existing[service_key] then
          table.insert(pending, tmpl)
        end
      end

      if #pending == 0 then
        if callback then callback() end
        return
      end

      local remaining = #pending
      for _, tmpl in ipairs(pending) do
        template.build_task(tmpl, {
          params = {},
          search = { dir = search_dir },
          disallow_prompt = true,
        }, function(err, task)
          if err then
            vim.notify("Failed to register service: " .. err, vim.log.levels.ERROR)
          elseif task then
            local key
            if spring_task(task) and task.metadata.task_key then
              key = "springboot::" .. task.metadata.task_key
            else
              key = "service::" .. task.name
            end
            if existing[key] then
              task:dispose()
            else
              existing[key] = true
            end
          end
          remaining = remaining - 1
          if remaining == 0 and callback then callback() end
        end)
      end
    end

    local function open_services(toggle)
      local origin_win = vim.api.nvim_get_current_win()
      local origin_tab = vim.api.nvim_get_current_tabpage()
      local root = find_project_root()
      roots_by_tab[origin_tab] = root
      ensure_services(root, function()
        local open_panel = function()
          if toggle then overseer.toggle() else overseer.open() end
        end
        if vim.api.nvim_win_is_valid(origin_win) then
          vim.api.nvim_win_call(origin_win, open_panel)
        else
          open_panel()
        end
        vim.schedule(refresh_winbar)
      end)
    end

    vim.api.nvim_create_user_command("OverseerToggle", function()
      open_services(true)
    end, { desc = "Toggle services panel", nargs = "?", bang = true })

    vim.api.nvim_create_user_command("OverseerOpen", function()
      open_services(false)
    end, { desc = "Open services panel", nargs = "?", bang = true })
  end,
}
