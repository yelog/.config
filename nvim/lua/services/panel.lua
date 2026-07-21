local catalog = require("services.catalog")

local M = {}

local Panel = {}
Panel.__index = Panel

local function find_project_root(source)
  local dir = source or vim.api.nvim_buf_get_name(0)
  if dir == "" then dir = vim.fn.getcwd() end
  if vim.fn.isdirectory(dir) ~= 1 then dir = vim.fn.fnamemodify(dir, ":p:h") end

  local last_marker = nil
  while dir and dir ~= "" do
    if vim.fn.isdirectory(dir .. "/.git") == 1 then return dir end
    if vim.fn.filereadable(dir .. "/pom.xml") == 1
      or vim.fn.filereadable(dir .. "/build.gradle") == 1
      or vim.fn.filereadable(dir .. "/build.gradle.kts") == 1
      or vim.fn.filereadable(dir .. "/package.json") == 1 then
      last_marker = dir
    end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then break end
    dir = parent
  end
  return last_marker or vim.fn.getcwd()
end

local function panel_valid(panel)
  return panel
    and vim.api.nvim_win_is_valid(panel.list_win)
    and vim.api.nvim_win_is_valid(panel.output_win)
end

local function set_buffer_options(bufnr, filetype)
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "hide"
  vim.bo[bufnr].buflisted = false
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].filetype = filetype
end

local function set_list_window_options(winid)
  vim.api.nvim_set_option_value("number", false, { scope = "local", win = winid })
  vim.api.nvim_set_option_value("relativenumber", false, { scope = "local", win = winid })
  vim.api.nvim_set_option_value("signcolumn", "no", { scope = "local", win = winid })
  vim.api.nvim_set_option_value("foldcolumn", "0", { scope = "local", win = winid })
  vim.api.nvim_set_option_value("wrap", false, { scope = "local", win = winid })
  vim.api.nvim_set_option_value("winfixheight", true, { scope = "local", win = winid })
end

local function set_empty_output_options(winid)
  vim.api.nvim_set_option_value("number", false, { scope = "local", win = winid })
  vim.api.nvim_set_option_value("relativenumber", false, { scope = "local", win = winid })
  vim.api.nvim_set_option_value("signcolumn", "no", { scope = "local", win = winid })
  vim.api.nvim_set_option_value("foldcolumn", "0", { scope = "local", win = winid })
  vim.api.nvim_set_option_value("wrap", true, { scope = "local", win = winid })
  vim.api.nvim_set_option_value("linebreak", true, { scope = "local", win = winid })
  vim.api.nvim_set_option_value("winfixheight", true, { scope = "local", win = winid })
end

local function status_visual(service)
  if service.status == "FAILED" then
    return "x", "DiagnosticError", "failed", "DiagnosticError"
  elseif service.status == "DEBUGGING" then
    return "*", "DiagnosticInfo", "debugging", "DiagnosticInfo"
  elseif service.status == "STOPPING" then
    return "~", "DiagnosticWarn", "stopping", "DiagnosticWarn"
  elseif service.status == "RESTART_PENDING" then
    return "~", "DiagnosticWarn", "restarting", "DiagnosticWarn"
  elseif service.status == "RUNNING" and service.metadata.ready then
    local detail = service.metadata.port and (":" .. service.metadata.port) or "ready"
    return "o", "DiagnosticOk", detail, "DiagnosticInfo"
  elseif service.status == "RUNNING" or service.status == "STARTING" then
    return "~", "DiagnosticWarn", "starting", "DiagnosticWarn"
  end
  return "o", "Comment", "stopped", "Comment"
end

local function sort_rank(service)
  if service.status == "FAILED" then return 1 end
  if service.status == "DEBUGGING" then return 2 end
  if service.status == "RUNNING" and service.metadata.ready then return 2 end
  if service.status == "RUNNING" or service.status == "STARTING" then return 3 end
  if service.status == "RESTART_PENDING" or service.status == "STOPPING" then return 4 end
  return 5
end

local function sorted_services(runtime, root)
  local services = runtime:list(root)
  table.sort(services, function(a, b)
    local rank_a = sort_rank(a)
    local rank_b = sort_rank(b)
    if rank_a ~= rank_b then return rank_a < rank_b end
    return a.name < b.name
  end)
  return services
end

local help_items = {
  { "?", "Show this help" },
  { "<CR>", "Start service or focus its log" },
  { "s", "Start service" },
  { "r", "Restart service" },
  { "S", "Stop service" },
  { "dd", "Dispose service" },
  { "<leader>d", "Debug Spring Boot service" },
  { "u", "Open detected service URL" },
  { "a", "Manage selected services" },
  { "p", "Select Spring profile" },
  { "q", "Close Services panel" },
}

function Panel.winbar_text(context)
  local present = {}
  for _, key in ipairs(context.selected or {}) do
    local service_type = key:match("^([^:]+)::")
    if service_type then present[service_type] = true end
  end
  for _, service in ipairs(context.services or {}) do
    if service.service_type then present[service.service_type] = true end
  end

  local titles = {}
  for _, type_info in ipairs(catalog.list_types()) do
    if present[type_info.service_type] then table.insert(titles, type_info.title) end
  end
  local title = #titles > 0 and (table.concat(titles, " + ") .. " SERVICES") or "SERVICES"
  local count = #(context.selected or {})
  local text = string.format("%s  %d selected  [a %s]", title, count, count == 0 and "add" or "manage")
  if present.springboot and context.profile then text = text .. "  ◆ profile: " .. context.profile .. "  [p switch]" end
  return text
end

function Panel:_panel_for_tab(tab)
  return self.panels[tab or vim.api.nvim_get_current_tabpage()]
end

function Panel:_remembered_key(tab, root)
  local tab_focus = self.focused_keys[tab]
  return tab_focus and tab_focus[vim.fs.normalize(root)] or nil
end

function Panel:_remember_focus(panel, key)
  if not key then return end
  local root = vim.fs.normalize(panel.root)
  self.focused_keys[panel.tab] = self.focused_keys[panel.tab] or {}
  self.focused_keys[panel.tab][root] = key
end

function Panel:_service_for_cursor(panel)
  if not panel_valid(panel) then return nil end
  local line = vim.api.nvim_win_get_cursor(panel.list_win)[1]
  local key = panel.rows[line]
  return key and self.runtime:get(key) or nil
end

function Panel:_output_state(panel, service)
  local state = panel.output_states[service.key]
  if not state then
    state = { following = true, unseen_lines = 0, view = nil }
    panel.output_states[service.key] = state
  end
  return state
end

function Panel:_displayed_normal_output(panel)
  if not panel_valid(panel) then return nil end
  local service = panel.focused_key and self.runtime:get(panel.focused_key) or nil
  if not service or service.terminal_output or not service.output then return nil end
  if vim.api.nvim_win_get_buf(panel.output_win) ~= service.output.bufnr then return nil end
  return service
end

function Panel:_active_normal_output(panel)
  if vim.api.nvim_get_current_win() ~= panel.output_win then return nil end
  return self:_displayed_normal_output(panel)
end

function Panel:_set_output_winbar(panel, state)
  if not panel or not vim.api.nvim_win_is_valid(panel.output_win) then return end
  if not state then
    vim.wo[panel.output_win].winbar = ""
  elseif state.following then
    vim.wo[panel.output_win].winbar = "LOG [FOLLOW]"
  else
    vim.wo[panel.output_win].winbar = string.format("LOG [PAUSED - %d new - G tail]", state.unseen_lines)
  end
end

function Panel:_tail_output(panel)
  if not panel_valid(panel) then return false end
  local ok = pcall(vim.api.nvim_win_call, panel.output_win, function()
    vim.cmd("normal! G")
  end)
  return ok
end

function Panel:_output_at_tail(panel)
  if not panel_valid(panel) then return false end
  local ok, at_tail = pcall(vim.api.nvim_win_call, panel.output_win, function()
    local last_line = vim.api.nvim_buf_line_count(0)
    return vim.api.nvim_win_get_cursor(0)[1] == last_line and vim.fn.line("w$") >= last_line
  end)
  return ok and at_tail or false
end

function Panel:_save_output_view(panel, service)
  service = service or self:_displayed_normal_output(panel)
  if not service then return end
  local state = self:_output_state(panel, service)
  if state.following then return end
  local ok, view = pcall(vim.api.nvim_win_call, panel.output_win, function()
    return vim.fn.winsaveview()
  end)
  if ok then state.view = view end
end

function Panel:_restore_output_view(panel, state, trimmed)
  if not panel_valid(panel) or not state.view then return end
  local view = vim.deepcopy(state.view)
  if trimmed and trimmed > 0 then
    for _, field in ipairs({ "lnum", "topline" }) do
      if view[field] then view[field] = math.max(1, view[field] - trimmed) end
    end
    state.view = view
  end
  pcall(vim.api.nvim_win_call, panel.output_win, function()
    vim.fn.winrestview(view)
  end)
end

function Panel:_update_output_following(panel)
  local service = self:_active_normal_output(panel)
  if not service then return end
  local state = self:_output_state(panel, service)
  if self:_output_at_tail(panel) then
    state.following = true
    state.unseen_lines = 0
    state.view = nil
  else
    state.following = false
    self:_save_output_view(panel, service)
  end
  self:_set_output_winbar(panel, state)
end

function Panel:_pause_output_for_search(panel)
  local service = self:_active_normal_output(panel)
  if not service then return end
  local state = self:_output_state(panel, service)
  state.following = false
  self:_save_output_view(panel, service)
  self:_set_output_winbar(panel, state)
end

function Panel:_handle_output_rendered(panel, service, detail)
  local bufnr = detail and detail.bufnr or nil
  if not panel_valid(panel) or panel.focused_key ~= service.key or service.terminal_output
    or not service.output or service.output.bufnr ~= bufnr
    or vim.api.nvim_win_get_buf(panel.output_win) ~= bufnr then
    return
  end

  local state = self:_output_state(panel, service)
  if state.following then
    self:_tail_output(panel)
  else
    state.unseen_lines = state.unseen_lines + math.max(0, detail.appended or 0)
    self:_restore_output_view(panel, state, detail.trimmed)
  end
  self:_set_output_winbar(panel, state)
end

function Panel:_show_output(panel, service)
  if not panel_valid(panel) or not service then return false end
  local bufnr = self.runtime:get_output_bufnr(service.key)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then return false end
  vim.api.nvim_win_set_buf(panel.output_win, bufnr)
  if service.terminal_output then
    set_empty_output_options(panel.output_win)
    self:_set_output_winbar(panel)
  elseif service.output then
    service.output:configure_window(panel.output_win)
    if bufnr == service.output.bufnr then
      local state = self:_output_state(panel, service)
      if state.following then
        self:_tail_output(panel)
      else
        self:_restore_output_view(panel, state)
      end
      self:_set_output_winbar(panel, state)
    else
      self:_set_output_winbar(panel)
    end
  else
    self:_set_output_winbar(panel)
  end
  return true
end

function Panel:focus(panel, key)
  local service = self.runtime:get(key)
  if not service or vim.fs.normalize(panel.root) ~= vim.fs.normalize(service.metadata.project_root) then return false end
  if panel.focused_key ~= key then self:_save_output_view(panel) end
  panel.focused_key = key
  self:_remember_focus(panel, key)
  self:_show_output(panel, service)
  return true
end

function Panel:_restore_focus(panel)
  local key = self:_remembered_key(panel.tab, panel.root)
  if not key then return false end

  local row
  for index, row_key in ipairs(panel.rows) do
    if row_key == key then
      row = index
      break
    end
  end
  if not row or not self:focus(panel, key) then return false end
  vim.api.nvim_win_set_cursor(panel.list_win, { row, 0 })
  return true
end

function Panel:show_help(panel)
  if panel.help_win and vim.api.nvim_win_is_valid(panel.help_win) then
    vim.api.nvim_win_close(panel.help_win, true)
    panel.help_win = nil
    return nil
  end

  local lines = { "Services keybindings", "" }
  local key_width = 0
  for _, item in ipairs(help_items) do
    key_width = math.max(key_width, vim.fn.strdisplaywidth(item[1]))
  end
  for _, item in ipairs(help_items) do
    table.insert(lines, string.format("  %-" .. key_width .. "s  %s", item[1], item[2]))
  end
  table.insert(lines, "")
  table.insert(lines, "  Press ?, q, or <Esc> to close")

  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end
  width = math.min(math.max(width + 2, 40), vim.o.columns - 4)
  local height = math.min(#lines, vim.o.lines - 4)
  local bufnr = vim.api.nvim_create_buf(false, true)
  set_buffer_options(bufnr, "ServicesHelp")
  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable = false

  local winid = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.max(0, math.floor((vim.o.lines - height) / 2)),
    col = math.max(0, math.floor((vim.o.columns - width) / 2)),
    style = "minimal",
    border = "rounded",
    title = " Services Keys ",
    title_pos = "center",
  })
  vim.api.nvim_set_option_value("wrap", false, { scope = "local", win = winid })
  vim.api.nvim_set_option_value("number", false, { scope = "local", win = winid })
  vim.api.nvim_set_option_value("relativenumber", false, { scope = "local", win = winid })
  vim.api.nvim_set_option_value("signcolumn", "no", { scope = "local", win = winid })
  panel.help_win = winid

  local function close_help()
    if vim.api.nvim_win_is_valid(winid) then vim.api.nvim_win_close(winid, true) end
  end
  for _, lhs in ipairs({ "?", "q", "<Esc>" }) do
    vim.keymap.set("n", lhs, close_help, { buffer = bufnr, silent = true })
  end
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(winid),
    once = true,
    callback = function()
      if panel.help_win == winid then panel.help_win = nil end
    end,
  })
  return winid
end

function Panel:stop_service(service, callback)
  local java_debug = require("custom.java_debug")
  if java_debug.is_debugging(service.key) then
    return java_debug.terminate(service.key, callback)
  end
  return self.runtime:stop(service.key)
end

function Panel:restart_service(panel, service)
  local java_debug = require("custom.java_debug")
  local profile = self.state.get_profile(panel.root)
  if java_debug.is_debugging(service.key) then
    return java_debug.terminate(service.key, function()
      self.runtime:start(service.key, { profile = profile })
    end)
  end
  return self.runtime:restart(service.key, { profile = profile })
end

function Panel:dispose_service(service)
  local java_debug = require("custom.java_debug")
  if java_debug.is_debugging(service.key) then
    return java_debug.terminate(service.key, function() self.runtime:dispose(service.key) end)
  end
  if service.status == "RUNNING" or service.status == "STARTING" or service.status == "STOPPING" then
    local unsubscribe
    unsubscribe = service:subscribe(function(event)
      if event.type == "stopped" then
        if unsubscribe then unsubscribe() end
        self.runtime:dispose(service.key)
      end
    end)
    if self.runtime:stop(service.key) then return true end
    if unsubscribe then unsubscribe() end
  end
  return self.runtime:dispose(service.key)
end

function Panel:debug_service(panel, service)
  if service.service_type ~= "springboot" then
    vim.notify("Debug is available only for Spring Boot services", vim.log.levels.WARN)
    return false
  end
  local java_debug = require("custom.java_debug")
  local function launch()
    java_debug.start(service.key)
  end
  if service.status == "RUNNING" or service.status == "STARTING" then
    local unsubscribe
    unsubscribe = service:subscribe(function(event)
      if event.type == "stopped" then
        if unsubscribe then unsubscribe() end
        vim.schedule(launch)
      end
    end)
    return self:stop_service(service)
  end
  launch()
  return true
end

function Panel:render(panel)
  if not panel_valid(panel) then return false end
  local services = sorted_services(self.runtime, panel.root)
  local selected = self.state.get_selected_services(panel.root)
  local profile = self.state.get_profile(panel.root)
  local lines = {}
  local highlights = {}
  panel.rows = {}
  vim.api.nvim_buf_clear_namespace(panel.list_bufnr, panel.namespace, 0, -1)

  if #services == 0 then
    table.insert(lines, " No services selected. Press a to add services.")
  else
    for index, service in ipairs(services) do
      local status, status_hl, detail, detail_hl = status_visual(service)
      local type_info = catalog.get_type(service.service_type)
      local line = string.format(" %s %s %s  %s", status, type_info.icon, service.name, detail)
      table.insert(lines, line)
      panel.rows[index] = service.key
      table.insert(highlights, { index - 1, 1, 2, status_hl })
      table.insert(highlights, { index - 1, 3, 3 + #type_info.icon, type_info.hl })
      table.insert(highlights, { index - 1, #line - #detail, #line, detail_hl })
    end
  end

  vim.bo[panel.list_bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(panel.list_bufnr, 0, -1, false, lines)
  vim.bo[panel.list_bufnr].modifiable = false
  for _, highlight in ipairs(highlights) do
    vim.api.nvim_buf_set_extmark(panel.list_bufnr, panel.namespace, highlight[1], highlight[2], {
      end_col = highlight[3],
      hl_group = highlight[4],
    })
  end
  vim.wo[panel.list_win].winbar = Panel.winbar_text({ selected = selected, services = services, profile = profile })

  if panel.focused_key and self.runtime:get(panel.focused_key) then self:focus(panel, panel.focused_key) end
  return true
end

function Panel:_configure_keymaps(panel)
  local function current_service()
    return self:_service_for_cursor(panel)
  end
  vim.keymap.set("n", "q", function() self:close() end, { buffer = panel.list_bufnr, silent = true })
  vim.keymap.set("n", "?", function() self:show_help(panel) end, { buffer = panel.list_bufnr, silent = true })
  vim.keymap.set("n", "<CR>", function()
    local service = current_service()
    if not service then return end
    if service.status == "RUNNING" or service.status == "STARTING" or service.status == "DEBUGGING" then
      self:focus(panel, service.key)
    else
      self.runtime:start(service.key, { profile = self.state.get_profile(panel.root) })
    end
  end, { buffer = panel.list_bufnr, silent = true })
  vim.keymap.set("n", "s", function()
    local service = current_service()
    if service then self.runtime:start(service.key, { profile = self.state.get_profile(panel.root) }) end
  end, { buffer = panel.list_bufnr, silent = true })
  vim.keymap.set("n", "r", function()
    local service = current_service()
    if service then self:restart_service(panel, service) end
  end, { buffer = panel.list_bufnr, silent = true })
  vim.keymap.set("n", "S", function()
    local service = current_service()
    if service then self:stop_service(service) end
  end, { buffer = panel.list_bufnr, silent = true })
  vim.keymap.set("n", "dd", function()
    local service = current_service()
    if service then self:dispose_service(service) end
  end, { buffer = panel.list_bufnr, silent = true })
  vim.keymap.set("n", "<leader>d", function()
    local service = current_service()
    if service then self:debug_service(panel, service) end
  end, { buffer = panel.list_bufnr, silent = true })
  vim.keymap.set("n", "u", function()
    local service = current_service()
    local url = service and service.metadata.ready and service.metadata.url or nil
    if not url then
      vim.notify("Service is not ready or no application URL was detected", vim.log.levels.WARN)
      return
    end
    local _, err = vim.ui.open(url)
    if err then vim.notify("Failed to open service URL: " .. err, vim.log.levels.ERROR) end
  end, { buffer = panel.list_bufnr, silent = true })
  vim.keymap.set("n", "a", function() self:manage(panel) end, { buffer = panel.list_bufnr, silent = true })
  vim.keymap.set("n", "p", function() self:select_profile(panel) end, { buffer = panel.list_bufnr, silent = true })
end

function Panel:_destroy(panel)
  if not panel then return end
  if self.panels[panel.tab] == panel then self.panels[panel.tab] = nil end
  if panel.augroup then
    pcall(vim.api.nvim_del_augroup_by_id, panel.augroup)
    panel.augroup = nil
  end
end

function Panel:_create(root)
  local tab = vim.api.nvim_get_current_tabpage()
  vim.cmd("botright new")
  local list_win = vim.api.nvim_get_current_win()
  local list_bufnr = vim.api.nvim_get_current_buf()
  set_buffer_options(list_bufnr, "ServicesList")
  set_list_window_options(list_win)
  vim.cmd("belowright vsplit")
  local output_win = vim.api.nvim_get_current_win()
  local empty_output = vim.api.nvim_create_buf(false, true)
  set_buffer_options(empty_output, "ServicesLog")
  vim.api.nvim_win_set_buf(output_win, empty_output)
  set_empty_output_options(output_win)
  vim.cmd("resize 16")
  local available_width = vim.api.nvim_win_get_width(list_win) + vim.api.nvim_win_get_width(output_win)
  vim.api.nvim_win_set_width(list_win, math.max(1, math.floor(available_width / 4)))
  local augroup = vim.api.nvim_create_augroup("ServicesPanel_" .. list_bufnr, { clear = true })

  local panel = {
    root = root,
    tab = tab,
    list_win = list_win,
    list_bufnr = list_bufnr,
    output_win = output_win,
    empty_output = empty_output,
    namespace = vim.api.nvim_create_namespace("services_panel_" .. list_bufnr),
    rows = {},
    focused_key = nil,
    output_states = {},
    augroup = augroup,
  }
  self.panels[tab] = panel
  self:_configure_keymaps(panel)

  vim.api.nvim_create_autocmd("CursorMoved", {
    group = augroup,
    buffer = list_bufnr,
    callback = function()
      local service = self:_service_for_cursor(panel)
      if service then self:focus(panel, service.key) end
    end,
  })
  vim.api.nvim_create_autocmd({ "CursorMoved", "WinScrolled" }, {
    group = augroup,
    callback = function()
      self:_update_output_following(panel)
    end,
  })
  vim.api.nvim_create_autocmd("CmdlineEnter", {
    group = augroup,
    callback = function(args)
      if args.match == "/" or args.match == "?" then self:_pause_output_for_search(panel) end
    end,
  })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = augroup,
    pattern = tostring(list_win),
    once = true,
    callback = function()
      if self.panels[tab] ~= panel then return end
      self:_destroy(panel)
      if vim.api.nvim_win_is_valid(output_win) then pcall(vim.api.nvim_win_close, output_win, true) end
    end,
  })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = augroup,
    pattern = tostring(output_win),
    once = true,
    callback = function()
      if self.panels[tab] ~= panel then return end
      self:_destroy(panel)
      if vim.api.nvim_win_is_valid(list_win) then pcall(vim.api.nvim_win_close, list_win, true) end
    end,
  })

  return panel
end

function Panel:open(root)
  root = root or find_project_root()
  local definitions = self.discover(root)
  local selected = self.state.get_selected_services(root)
  self.runtime:reconcile(root, definitions, selected)

  local tab = vim.api.nvim_get_current_tabpage()
  local panel = self.panels[tab]
  if not panel_valid(panel) then
    self:_destroy(panel)
    panel = self:_create(root)
  else
    if vim.fs.normalize(panel.root) ~= vim.fs.normalize(root) then panel.output_states = {} end
    panel.root = root
  end
  panel.focused_key = nil
  self:render(panel)
  self:_restore_focus(panel)
  if vim.api.nvim_win_is_valid(panel.list_win) then vim.api.nvim_set_current_win(panel.list_win) end
  return panel
end

function Panel:close(tab)
  tab = tab or vim.api.nvim_get_current_tabpage()
  local panel = self.panels[tab]
  if not panel then return false end
  self:_remember_focus(panel, panel.focused_key)
  self:_destroy(panel)
  if panel.help_win and vim.api.nvim_win_is_valid(panel.help_win) then pcall(vim.api.nvim_win_close, panel.help_win, true) end
  if vim.api.nvim_win_is_valid(panel.output_win) then pcall(vim.api.nvim_win_close, panel.output_win, true) end
  if vim.api.nvim_win_is_valid(panel.list_win) then pcall(vim.api.nvim_win_close, panel.list_win, true) end
  return true
end

function Panel:toggle(root)
  local panel = self:_panel_for_tab()
  if panel_valid(panel) then return self:close() end
  return self:open(root)
end

function Panel:select_profile(panel)
  local profiles = self.state.parse_maven_profiles(panel.root)
  if #profiles == 0 then
    vim.notify("No Maven profiles found in " .. panel.root .. "/pom.xml", vim.log.levels.WARN)
    return
  end
  local choices = { { label = "[no profile]", profile = nil } }
  for _, profile in ipairs(profiles) do
    table.insert(choices, { label = profile, profile = profile })
  end
  local current = self.state.get_profile(panel.root)
  vim.ui.select(choices, {
    prompt = "Spring profile",
    format_item = function(item) return (item.profile == current and "* " or "  ") .. item.label end,
  }, function(choice)
    if not choice or not self.state.set_profile(panel.root, choice.profile) then return end
    for _, service in ipairs(self.runtime:list(panel.root)) do
      if service.service_type == "springboot" and service.status == "RUNNING" then
        self.runtime:restart(service.key, { profile = choice.profile })
      end
    end
    self:render(panel)
  end)
end

function Panel:manage(panel)
  local definitions = self.discover(panel.root)
  if #definitions == 0 then
    vim.notify("No service launch entries found in " .. panel.root, vim.log.levels.WARN)
    return
  end
  local selected = self.state.get_selected_services(panel.root)
  local selected_lookup = {}
  for _, key in ipairs(selected) do
    selected_lookup[key] = true
  end

  local categories = {}
  for _, type_info in ipairs(catalog.list_types()) do
    local available, selected_count = 0, 0
    for _, definition in ipairs(definitions) do
      if definition.service_type == type_info.service_type then
        available = available + 1
        if selected_lookup[definition.key] then selected_count = selected_count + 1 end
      end
    end
    if available > 0 then
      table.insert(categories, {
        service_type = type_info.service_type,
        label = string.format("%s %s (%d/%d selected)", type_info.icon, type_info.label, selected_count, available),
      })
    end
  end

  vim.ui.select(categories, {
    prompt = "Service category",
    format_item = function(item) return item.label end,
  }, function(category)
    if not category then return end
    local items = {}
    for _, definition in ipairs(definitions) do
      if definition.service_type == category.service_type then
        local mark = selected_lookup[definition.key] and "*" or "o"
        table.insert(items, string.format("%s\t%s %s", definition.key, mark, definition.name))
      end
    end
    table.insert(items, "__clear__\tx Clear this category")
    require("fzf-lua").fzf_exec(items, {
      prompt = "Toggle services (Tab multi-select)> ",
      fzf_opts = { ["--multi"] = true, ["--delimiter"] = "\t", ["--with-nth"] = "2.." },
      actions = {
        enter = function(chosen)
          local replacement_lookup = {}
          for _, definition in ipairs(definitions) do
            if definition.service_type == category.service_type and selected_lookup[definition.key] then
              replacement_lookup[definition.key] = true
            end
          end
          local clear = false
          for _, item in ipairs(chosen or {}) do
            local key = item:match("^([^\t]+)")
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
          local updated = catalog.replace_category(selected, definitions, category.service_type, replacement, clear)
          if not self.state.set_selected_services(panel.root, updated) then
            vim.notify("Failed to persist service selection", vim.log.levels.ERROR)
            return
          end
          self.runtime:reconcile(panel.root, definitions, updated)
          self:render(panel)
        end,
      },
    })
  end)
end

function Panel:_on_runtime_event(event)
  local service = event.service
  if not service then return end
  if event.type == "output_rendered" then
    vim.schedule(function()
      for _, panel in pairs(self.panels) do
        if panel_valid(panel) and panel.root == service.metadata.project_root and panel.focused_key == service.key then
          self:_handle_output_rendered(panel, service, event.detail)
        end
      end
    end)
    return
  end

  vim.schedule(function()
    for _, panel in pairs(self.panels) do
      if panel_valid(panel) and panel.root == service.metadata.project_root then
        if event.type == "starting" and panel.focused_key == service.key and not service.terminal_output then
          local state = self:_output_state(panel, service)
          state.following = true
          state.unseen_lines = 0
          state.view = nil
        end
        if event.type == "disposed" and panel.focused_key == service.key then
          panel.focused_key = nil
          panel.output_states[service.key] = nil
          if vim.api.nvim_buf_is_valid(panel.empty_output) then
            vim.api.nvim_win_set_buf(panel.output_win, panel.empty_output)
            set_empty_output_options(panel.output_win)
            self:_set_output_winbar(panel)
          end
        end
        self:render(panel)
        if panel.focused_key == service.key then self:_show_output(panel, service) end
      end
    end
  end)
end

function M.new(opts)
  opts = opts or {}
  local controller = setmetatable({
    runtime = assert(opts.runtime or require("services.runtime").instance(), "runtime is required"),
    state = opts.state or require("services.state"),
    discover = opts.discover or function(root) return require("services.providers").discover(root) end,
    panels = {},
    focused_keys = {},
  }, Panel)
  controller.unsubscribe = controller.runtime:subscribe(function(event) controller:_on_runtime_event(event) end)
  return controller
end

M.find_project_root = find_project_root

local default_panel

function M.setup(opts)
  if not default_panel then default_panel = M.new(opts) end
  return default_panel
end

function M.instance()
  return default_panel or M.setup()
end

function M.open(root)
  return M.instance():open(root)
end

function M.close()
  return M.instance():close()
end

function M.toggle(root)
  return M.instance():toggle(root)
end

return M
