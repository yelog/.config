return {
  "stevearc/overseer.nvim",
  config = function()
    local overseer = require("overseer")
    local service_catalog = require("overseer.service_catalog")
    local service_state = require("overseer.service_state")
    local roots_by_tab = {}
    local manage_services

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
          or vim.fn.filereadable(dir .. "/build.gradle.kts") == 1
          or vim.fn.filereadable(dir .. "/package.json") == 1 then
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

    local function service_key(task)
      return service_catalog.key_from_metadata(task.metadata, task.name)
    end

    local function set_sidebar_root(root, create)
      local sidebar_module = require("overseer.task_list.sidebar")
      local sidebar = create and sidebar_module.get_or_create() or sidebar_module.get()
      if not sidebar then return end

      sidebar.list_task_opts.filter = function(task)
        return task.metadata
          and task.metadata.service == true
          and task.metadata.project_root == root
      end
      sidebar:render()
    end

    local function refresh_winbar()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == "OverseerList" then
          local tab = vim.api.nvim_win_get_tabpage(win)
          local root = roots_by_tab[tab]
          local selected = root and service_state.get_selected_services(root) or {}
          local present_types = {}
          for _, key in ipairs(selected) do
            local service_type = key:match("^([^:]+)::")
            if service_type then present_types[service_type] = true end
          end
          for _, task in ipairs(overseer.list_tasks({})) do
            if task.metadata and task.metadata.service and task.metadata.project_root == root then
              present_types[task.metadata.service_type or (task.metadata.springboot and "springboot")
                or (task.metadata.npm and "npm") or "service"] = true
            end
          end

          local title_parts = {}
          for _, type_info in ipairs(service_catalog.list_types()) do
            if present_types[type_info.service_type] then table.insert(title_parts, type_info.title) end
          end

          local title = #title_parts > 0 and (table.concat(title_parts, " + ") .. " SERVICES") or "SERVICES"
          local winbar_parts = { "%#Title# " .. title .. " %*" }
          local manage_label = #selected == 0 and "add" or "manage"
          table.insert(winbar_parts, string.format("%%#Comment# %d selected  [a %s] %%*", #selected, manage_label))

          if present_types.springboot then
            local profile = root and service_state.get_profile(root) or nil
            profile = (profile or "default"):gsub("%%", "%%%%")
            table.insert(winbar_parts, "%#DiagnosticInfo#◆ profile: " .. profile .. "%*")
            table.insert(winbar_parts, "%#Comment#  [p switch] %*")
          end

          vim.wo[win].winbar = table.concat(winbar_parts)
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
      elseif task.metadata and task.metadata.debugging then
        return "◆", "DiagnosticInfo", "debugging", "DiagnosticInfo"
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

    local function task_service_type(task)
      local metadata = task.metadata or {}
      local service_type = metadata.service_type
        or (metadata.springboot and "springboot")
        or (metadata.npm and "npm")
        or "service"
      return service_catalog.get_type(service_type)
    end

    local function sort_rank(task)
      if task.status == "FAILURE" then return 1 end
      if task.metadata and task.metadata.debugging then return 2 end
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
          local service_type = task_service_type(task)
          return {
            {
              { " " .. icon .. " ", icon_hl },
              { service_type.icon .. " ", service_type.hl },
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
          ["a"] = { function() manage_services() end, desc = "Manage services" },
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
          ["dd"] = { "keymap.run_action", opts = { action = "dispose_service" }, desc = "Dispose" },
          ["<leader>d"] = { "keymap.run_action", opts = { action = "debug_service" }, desc = "Debug" },
        },
      },
      actions = {
        ["smart_enter"] = {
          desc = "Start or open",
          run = function(task)
            if require("custom.java_debug").is_debugging(task) then
              require("dap").repl.open()
            elseif task.status == "RUNNING" then
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
            local java_debug = require("custom.java_debug")
            if java_debug.is_debugging(task) then
              java_debug.terminate(task, function()
                task:reset()
                task:start()
              end)
              return
            end
            if task.status ~= "RUNNING" then
              task:reset()
              task:start()
            end
          end,
        },
        ["restart_service"] = {
          desc = "Restart service",
          run = function(task)
            local java_debug = require("custom.java_debug")
            if java_debug.is_debugging(task) then
              java_debug.terminate(task, function() java_debug.start(task) end)
              return
            end
            task:restart(true)
          end,
        },
        ["stop_service"] = {
          desc = "Stop service",
          run = function(task)
            if require("custom.java_debug").terminate(task) then return end
            if task.status == "RUNNING" then task:stop() end
          end,
        },
        ["dispose_service"] = {
          desc = "Dispose service",
          run = function(task)
            local java_debug = require("custom.java_debug")
            if java_debug.is_debugging(task) then
              java_debug.terminate(task, function() task:dispose() end)
            else
              task:dispose()
            end
          end,
        },
        ["start_all_services"] = {
          desc = "Start all services",
          run = function()
            for _, task in ipairs(overseer.list_tasks({})) do
              if task.metadata and task.metadata.service
                and task.status ~= "RUNNING"
                and not require("custom.java_debug").is_debugging(task) then
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
              if task.metadata and task.metadata.service then
                if not require("custom.java_debug").terminate(task) and task.status == "RUNNING" then
                  task:stop()
                end
              end
            end
          end,
        },
        ["open_service_url"] = {
          desc = "Open service URL",
          condition = function(task)
            return spring_task(task) or (task.metadata and task.metadata.npm)
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
        ["debug_service"] = {
          desc = "Debug service",
          condition = function(task)
            return spring_task(task)
          end,
          run = function(task)
            local java_debug = require("custom.java_debug")
            local function launch() java_debug.start(task) end
            if task.status == "RUNNING" then
              task:subscribe("on_complete", function()
                vim.schedule(launch)
                return true
              end)
              task:stop()
            else
              launch()
            end
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
    vim.api.nvim_create_autocmd("TabEnter", {
      group = panel_group,
      callback = function()
        local root = roots_by_tab[vim.api.nvim_get_current_tabpage()]
        if root then set_sidebar_root(root, false) end
      end,
    })

    local function reconcile_services(search_dir, entries, callback)
      local template = require("overseer.template")
      local selected = service_state.get_selected_services(search_dir)
      local selected_lookup = {}
      for _, key in ipairs(selected) do
        selected_lookup[key] = true
      end
      local existing = {}
      local retained_running = 0
      for _, task in ipairs(overseer.list_tasks({})) do
        if task.metadata and task.metadata.service and task.metadata.project_root == search_dir then
          local key = service_key(task)
          if key and selected_lookup[key] then
            existing[key] = true
          elseif key then
            local debugging = require("custom.java_debug").is_debugging(task)
            if task.status == "RUNNING" or debugging then
              retained_running = retained_running + 1
            else
              task:dispose(true)
            end
          end
        end
      end

      local pending = {}
      for _, entry in ipairs(service_catalog.filter_selected(entries, selected)) do
        if not existing[entry.key] then
          table.insert(pending, entry)
        end
      end

      if #pending == 0 then
        if retained_running > 0 then
          vim.notify("Deselected running services were kept; stop and dispose them to remove", vim.log.levels.WARN)
        end
        if callback then callback() end
        return
      end

      local remaining = #pending
      for _, entry in ipairs(pending) do
        template.build_task(entry.template, {
          params = {},
          search = { dir = search_dir },
          disallow_prompt = true,
        }, function(err, task)
          if err then
            vim.notify("Failed to register service: " .. err, vim.log.levels.ERROR)
          elseif task and existing[entry.key] then
              task:dispose()
          elseif task then
            existing[entry.key] = true
          end
          remaining = remaining - 1
          if remaining == 0 then
            if retained_running > 0 then
              vim.notify("Deselected running services were kept; stop and dispose them to remove", vim.log.levels.WARN)
            end
            if callback then callback() end
          end
        end)
      end
    end

    manage_services = function()
      local tab = vim.api.nvim_get_current_tabpage()
      local root = roots_by_tab[tab] or find_project_root()
      roots_by_tab[tab] = root
      local entries = service_catalog.discover(root)
      if #entries == 0 then
        vim.notify("No service launch entries found in " .. root, vim.log.levels.WARN)
        return
      end

      local selected = service_state.get_selected_services(root)
      local selected_lookup = {}
      for _, key in ipairs(selected) do
        selected_lookup[key] = true
      end

      local counts = {}
      for _, entry in ipairs(entries) do
        local count = counts[entry.service_type] or { available = 0, selected = 0 }
        count.available = count.available + 1
        if selected_lookup[entry.key] then count.selected = count.selected + 1 end
        counts[entry.service_type] = count
      end

      local categories = {}
      for _, type_info in ipairs(service_catalog.list_types()) do
        local service_type = type_info.service_type
        if counts[service_type] then
          table.insert(categories, {
            service_type = service_type,
            label = string.format("%s %s (%d/%d selected)", type_info.icon, type_info.label,
              counts[service_type].selected, counts[service_type].available),
          })
        end
      end

      vim.ui.select(categories, {
        prompt = "Service category",
        format_item = function(item) return item.label end,
      }, function(category)
        if not category then return end

        local picker_items = {}
        for _, entry in ipairs(entries) do
          if entry.service_type == category.service_type then
            local mark = selected_lookup[entry.key] and "●" or "○"
            local icon = service_catalog.get_type(entry.service_type).icon
            table.insert(picker_items, string.format("%s\t%s %s %s", entry.key, mark, icon, entry.name))
          end
        end
        table.insert(picker_items, "__clear__\t× Clear this category")

        require("fzf-lua").fzf_exec(picker_items, {
          prompt = "Toggle services (Tab multi-select)> ",
          fzf_opts = {
            ["--multi"] = true,
            ["--delimiter"] = "\t",
            ["--with-nth"] = "2..",
          },
          actions = {
            enter = function(chosen)
              local replacement_lookup = {}
              for _, entry in ipairs(entries) do
                if entry.service_type == category.service_type and selected_lookup[entry.key] then
                  replacement_lookup[entry.key] = true
                end
              end

              local clear = false
              for _, line in ipairs(chosen or {}) do
                local key = line:match("^([^\t]+)")
                if key == "__clear__" then
                  clear = true
                elseif key and replacement_lookup[key] then
                  replacement_lookup[key] = nil
                elseif key then
                  replacement_lookup[key] = true
                end
              end

              local replacement = {}
              if not clear then
                for key in pairs(replacement_lookup) do
                  table.insert(replacement, key)
                end
              end
              local updated = service_catalog.replace_category(
                selected,
                entries,
                category.service_type,
                replacement,
                clear
              )
              if not service_state.set_selected_services(root, updated) then
                vim.notify("Failed to persist service selection", vim.log.levels.ERROR)
                return
              end

              reconcile_services(root, entries, function()
                refresh_winbar()
                vim.notify(string.format("%s services: %d selected",
                  service_catalog.get_type(category.service_type).label, #replacement))
              end)
            end,
          },
        })
      end)
    end

    local function open_services(toggle)
      local origin_win = vim.api.nvim_get_current_win()
      local origin_tab = vim.api.nvim_get_current_tabpage()
      local root = find_project_root()
      roots_by_tab[origin_tab] = root
      local entries = service_catalog.discover(root)
      reconcile_services(root, entries, function()
        set_sidebar_root(root, true)
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
