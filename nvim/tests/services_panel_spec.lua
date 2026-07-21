local test_file = debug.getinfo(1, "S").source:gsub("^@", "")
local config_root = vim.fs.dirname(vim.fs.dirname(test_file))
package.path = table.concat({
  config_root .. "/lua/?.lua",
  config_root .. "/lua/?/init.lua",
  package.path,
}, ";")

local function assert_equal(expected, actual, message)
  if not vim.deep_equal(expected, actual) then
    error((message or "values differ")
      .. "\nexpected: " .. vim.inspect(expected)
      .. "\nactual:   " .. vim.inspect(actual))
  end
end

local function output_cursor(winid)
  return vim.api.nvim_win_call(winid, function()
    return vim.api.nvim_win_get_cursor(0)
  end)
end

local function output_view(winid)
  return vim.api.nvim_win_call(winid, function()
    return vim.fn.winsaveview()
  end)
end

local function output_bottom_line(winid)
  return vim.api.nvim_win_call(winid, function()
    return vim.fn.line("w$")
  end)
end

local function at_tail(winid)
  return vim.api.nvim_win_call(winid, function()
    local last_line = vim.api.nvim_buf_line_count(0)
    return vim.api.nvim_win_get_cursor(0)[1] == last_line and vim.fn.line("w$") >= last_line
  end)
end

local function log_batch(prefix, count)
  local lines = {}
  for index = 1, count do
    lines[index] = string.format("%s %d", prefix, index)
  end
  return table.concat(lines, "\n") .. "\n"
end

local root = "/panel-project"
local definitions = {
  {
    key = "springboot::orders",
    name = "OrdersApplication",
    service_type = "springboot",
    cmd = { "orders" },
    metadata = { project_root = root, ready = true, port = 8080, url = "http://localhost:8080" },
  },
  {
    key = "npm::web::dev",
    name = "web:dev",
    service_type = "npm",
    cmd = { "web" },
    metadata = { project_root = root, ready = false },
  },
}

local spawn_requests = {}
local runtime = require("services.runtime").new({
  spawn = function(_, _, on_exit)
    local process = { kill = function() end }
    table.insert(spawn_requests, { process = process, on_exit = on_exit })
    return process
  end,
})
local selected = { "npm::web::dev", "springboot::orders" }
local state = {
  get_selected_services = function() return selected end,
  set_selected_services = function(_, keys)
    selected = keys
    return true
  end,
  get_profile = function() return "dev" end,
  set_profile = function() return true end,
  parse_maven_profiles = function() return { "dev", "local" } end,
}

local panel = require("services.panel").new({
  runtime = runtime,
  state = state,
  discover = function() return vim.deepcopy(definitions) end,
})

assert_equal("SERVICES  0 selected  [a add]", panel.winbar_text({ selected = {}, services = {} }),
  "empty panels should advertise the add action")
assert_equal("SPRING + NPM SERVICES  2 selected  [a manage]  ◆ profile: dev  [p switch]", panel.winbar_text({
  selected = selected,
  services = definitions,
  profile = "dev",
}), "populated panels should summarize service types and profiles")

panel:open(root)
local instance = panel.panels[vim.api.nvim_get_current_tabpage()]
assert(instance, "opening a root should create a tab-local panel")
assert_equal(instance.list_win, vim.api.nvim_get_current_win(), "opening should focus the service list")
assert_equal(2, #instance.rows, "panel rows should reflect reconciled service records")
assert(vim.api.nvim_win_get_position(instance.list_win)[2] < vim.api.nvim_win_get_position(instance.output_win)[2],
  "the service list should remain left of the output pane regardless of splitright")
local list_width = vim.api.nvim_win_get_width(instance.list_win)
local output_width = vim.api.nvim_win_get_width(instance.output_win)
assert(math.abs(list_width * 3 - output_width) <= 3,
  "the service list and output pane should default to a 1:3 width ratio")
local lines = vim.api.nvim_buf_get_lines(instance.list_bufnr, 0, -1, false)
assert(lines[1]:find("web:dev", 1, true) or lines[2]:find("web:dev", 1, true),
  "panel list should render service names")

local orders = runtime:get("springboot::orders")
orders.output:push("stdout", log_batch("orders log", 32))
assert(vim.wait(500, function()
  return vim.api.nvim_buf_get_lines(orders.output.bufnr, -2, -1, false)[1] == "orders log 32"
end), "service output should render before panel selection")

assert(panel:focus(instance, orders.key), "focusing a row should select its service")
assert_equal(orders.output.bufnr, vim.api.nvim_win_get_buf(instance.output_win),
  "focused services should replace the output buffer in place")
assert_equal(true, vim.wo[instance.output_win].wrap, "normal output panes should soft-wrap")
assert_equal(true, vim.wo[instance.output_win].linebreak, "normal output panes should use linebreak")
assert(at_tail(instance.output_win), "normal output should tail when first shown")
assert_equal(instance.list_win, vim.api.nvim_get_current_win(), "tailing an initial output should retain list focus")

assert(panel:close(), "closing an open panel should succeed")
panel:open(root)
instance = panel.panels[vim.api.nvim_get_current_tabpage()]
assert_equal(instance.list_win, vim.api.nvim_get_current_win(), "reopening should focus the service list")
assert_equal(orders.key, instance.focused_key, "reopening should restore the focused service key")
assert_equal(orders.output.bufnr, vim.api.nvim_win_get_buf(instance.output_win),
  "reopening should restore the focused service output")
assert_equal(orders.key, instance.rows[vim.api.nvim_win_get_cursor(instance.list_win)[1]],
  "reopening should move the cursor to the focused service's current row")

assert(runtime:append_output(orders.key, "stdout", "following line\n"), "following output should append")
assert(vim.wait(500, function()
  return vim.api.nvim_buf_get_lines(orders.output.bufnr, -2, -1, false)[1] == "following line"
    and at_tail(instance.output_win)
end), "following output should tail after a rendered batch")
assert_equal(instance.list_win, vim.api.nvim_get_current_win(), "following output should not steal list focus")

local live_tail = vim.api.nvim_buf_line_count(orders.output.bufnr)
vim.api.nvim_win_call(instance.output_win, function()
  vim.api.nvim_win_set_cursor(0, { live_tail, 0 })
  vim.fn.winrestview({ lnum = live_tail, topline = 1 })
  vim.api.nvim_exec_autocmds("WinScrolled", { modeline = false })
end)
local output_state = instance.output_states[orders.key]
local paused_view = output_view(instance.output_win)
assert(output_bottom_line(instance.output_win) < live_tail,
  "test setup should move the output viewport away from the live tail")
assert_equal(false, output_state.following,
  "WinScrolled should pause follow when the viewport leaves tail despite a tail cursor")
assert_equal({ live_tail, 0 }, output_cursor(instance.output_win), "paused output should keep its cursor")

local list_changedtick = vim.api.nvim_buf_get_changedtick(instance.list_bufnr)
assert(runtime:append_output(orders.key, "stdout", "paused line\n"), "paused output should append")
assert(vim.wait(500, function()
  return output_state.unseen_lines == 1
    and vim.api.nvim_buf_get_lines(orders.output.bufnr, -2, -1, false)[1] == "paused line"
end), "paused output should count rendered lines")
assert_equal({ live_tail, 0 }, output_cursor(instance.output_win), "paused output should preserve its cursor after appending")
assert_equal(paused_view.topline, output_view(instance.output_win).topline,
  "paused output should preserve its viewport after appending")
assert(vim.wo[instance.output_win].winbar:find("PAUSED", 1, true), "paused state should be visible")
assert(vim.wo[instance.output_win].winbar:find("1 new", 1, true), "paused state should show unread lines")
assert_equal(list_changedtick, vim.api.nvim_buf_get_changedtick(instance.list_bufnr),
  "output_rendered should not re-render the services list")

vim.api.nvim_win_call(instance.output_win, function()
  vim.api.nvim_win_set_cursor(0, { vim.api.nvim_buf_line_count(0), 0 })
  vim.api.nvim_exec_autocmds("CursorMoved", { modeline = false })
end)
assert_equal(true, output_state.following, "reaching tail should resume follow")
assert_equal(0, output_state.unseen_lines, "reaching tail should clear unread lines")
assert(vim.wo[instance.output_win].winbar:find("FOLLOW", 1, true), "following state should be visible")

vim.api.nvim_win_call(instance.output_win, function()
  vim.api.nvim_exec_autocmds("CmdlineEnter", { pattern = "/", modeline = false })
end)
assert_equal(false, output_state.following, "search should pause follow before input")

vim.api.nvim_win_call(instance.output_win, function()
  local tail = vim.api.nvim_buf_line_count(0)
  vim.api.nvim_win_set_cursor(0, { tail - 1, 0 })
  vim.api.nvim_exec_autocmds("CursorMoved", { modeline = false })
  vim.api.nvim_win_set_cursor(0, { tail, 0 })
  vim.api.nvim_exec_autocmds("CursorMoved", { modeline = false })
end)
assert_equal(true, output_state.following, "returning to tail after search should resume follow")
assert(runtime:append_output(orders.key, "stdout", "resumed line\n"), "resumed output should append")
assert(vim.wait(500, function()
  return vim.api.nvim_buf_get_lines(orders.output.bufnr, -2, -1, false)[1] == "resumed line"
    and at_tail(instance.output_win)
end), "resumed output should tail subsequent rendered batches")
assert_equal(0, output_state.unseen_lines, "resumed output should remain caught up")
assert_equal(instance.list_win, vim.api.nvim_get_current_win(), "resumed output should not steal list focus")

instance = panel:open(root)
assert(instance.output_states[orders.key] == output_state,
  "reopening an already-open panel at the same root should retain output state")

output_state.following = false
output_state.unseen_lines = 2
assert(runtime:start(orders.key), "starting a focused service should reset its output state")
assert(vim.wait(500, function()
  return output_state.following and output_state.unseen_lines == 0
end), "starting should resume follow after clearing normal output")
spawn_requests[#spawn_requests].on_exit({ code = 0, signal = 0 })
assert_equal("STOPPED", orders.status, "started service should stop cleanly for disposal coverage")

local has_help_mapping = false
for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(instance.list_bufnr, "n")) do
  if mapping.lhs == "?" then has_help_mapping = true end
end
assert(has_help_mapping, "service list should map ? to its keyboard help")

local help_win = panel:show_help(instance)
assert(help_win and vim.api.nvim_win_is_valid(help_win), "help should open in a floating window")
local help_text = table.concat(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(help_win), 0, -1, false), "\n")
assert(help_text:find("?", 1, true), "help should document its own shortcut")
assert(help_text:find("<CR>", 1, true), "help should document start or focus")
assert(help_text:find("<leader>d", 1, true), "help should document Spring Boot debugging")
assert(help_text:find("dd", 1, true), "help should document disposal")
panel:show_help(instance)
assert_equal(false, vim.api.nvim_win_is_valid(help_win), "opening help again should close the existing help window")

assert(panel:dispose_service(orders), "disposing a stopped service should succeed")
assert(vim.wait(500, function()
  return runtime:get(orders.key) == nil
    and vim.api.nvim_win_is_valid(instance.output_win)
    and vim.api.nvim_win_get_buf(instance.output_win) == instance.empty_output
    and #instance.rows == 1
end), "disposing the focused service should retain the output split and refresh the list")

local web = runtime:get("npm::web::dev")
assert(runtime:start(web.key), "running-service disposal should start its process first")
assert(panel:focus(instance, web.key), "running service should become the focused output")
assert(panel:dispose_service(web), "disposing a running service should request a stop")
spawn_requests[#spawn_requests].on_exit({ code = 1, signal = 15 })
assert(vim.wait(500, function()
  return runtime:get(web.key) == nil
    and vim.api.nvim_win_is_valid(instance.output_win)
    and vim.api.nvim_win_get_buf(instance.output_win) == instance.empty_output
    and #instance.rows == 0
end), "disposing a running focused service should retain the output split and remove its row")

local same_root_alias = root .. "/."
local stale_output_state = { following = false, unseen_lines = 7, view = { lnum = 1, topline = 1 } }
assert_equal(vim.fs.normalize(root), vim.fs.normalize(same_root_alias),
  "test root aliases should normalize to the same project")
instance.output_states[orders.key] = stale_output_state
instance = panel:open(same_root_alias)
assert(instance.output_states[orders.key] == stale_output_state,
  "retargeting to the same normalized root should retain output state")
instance = panel:open("/other-panel-project")
assert_equal(nil, instance.output_states[orders.key],
  "retargeting to another root should clear stale output state for matching service keys")

panel:close()
runtime:dispose("springboot::orders")
runtime:dispose("npm::web::dev")
print("services-panel-tests: ok")
