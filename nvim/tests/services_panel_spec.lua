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
orders.output:push("stdout", "orders log\n")
assert(vim.wait(500, function()
  return vim.api.nvim_buf_get_lines(orders.output.bufnr, -2, -1, false)[1] == "orders log"
end), "service output should render before panel selection")

assert(panel:focus(instance, orders.key), "focusing a row should select its service")
assert_equal(orders.output.bufnr, vim.api.nvim_win_get_buf(instance.output_win),
  "focused services should replace the output buffer in place")
assert_equal(true, vim.wo[instance.output_win].wrap, "normal output panes should soft-wrap")
assert_equal(true, vim.wo[instance.output_win].linebreak, "normal output panes should use linebreak")

assert(panel:close(), "closing an open panel should succeed")
panel:open(root)
instance = panel.panels[vim.api.nvim_get_current_tabpage()]
assert_equal(instance.list_win, vim.api.nvim_get_current_win(), "reopening should focus the service list")
assert_equal(orders.key, instance.focused_key, "reopening should restore the focused service key")
assert_equal(orders.output.bufnr, vim.api.nvim_win_get_buf(instance.output_win),
  "reopening should restore the focused service output")
assert_equal(orders.key, instance.rows[vim.api.nvim_win_get_cursor(instance.list_win)[1]],
  "reopening should move the cursor to the focused service's current row")

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

panel:close()
runtime:dispose("springboot::orders")
runtime:dispose("npm::web::dev")
print("services-panel-tests: ok")
