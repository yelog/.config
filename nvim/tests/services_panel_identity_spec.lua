local test_file = debug.getinfo(1, "S").source:gsub("^@", "")
local config_root = vim.fs.dirname(vim.fs.dirname(test_file))
package.path = table.concat({
  config_root .. "/lua/?.lua",
  config_root .. "/lua/?/init.lua",
  package.path,
}, ";")

local function assert_equal(expected, actual, message)
  if not vim.deep_equal(expected, actual) then
    error(
      (message or "values differ") .. "\nexpected: " .. vim.inspect(expected) .. "\nactual:   " .. vim.inspect(actual)
    )
  end
end

vim.o.columns = 200
vim.o.lines = 40
vim.o.cursorline = true
vim.api.nvim_set_hl(0, "Normal", { fg = "#BCBEC4", bg = "#191A1C", ctermfg = 250, ctermbg = 234 })
vim.api.nvim_set_hl(0, "TabLineSel", { fg = "#D1D2D9", bg = "#243656", ctermbg = 17 })
vim.api.nvim_set_hl(0, "DiagnosticSignInfo", { fg = "#5D9BEB", ctermfg = 75 })
vim.api.nvim_set_hl(0, "DiagnosticOk", { fg = "#6AAA73", ctermfg = 2 })

local root = "/panel-identity-project"
local definitions = {
  {
    key = "springboot::orders",
    name = "MossServiceCommonServerApplication",
    service_type = "springboot",
    metadata = { project_root = root, ready = true, port = 8000 },
  },
  {
    key = "springboot::auth",
    name = "MossAuthApplication",
    service_type = "springboot",
    metadata = { project_root = root, ready = true, port = 7002 },
  },
}
local selected = vim.tbl_map(function(definition)
  return definition.key
end, definitions)
local runtime = require("services.runtime").new()
local controller = require("services.panel").new({
  runtime = runtime,
  state = {
    get_selected_services = function()
      return selected
    end,
    has_selected_services = function()
      return true
    end,
    get_profile = function()
      return "moss-sit"
    end,
  },
  discover = function(project_root)
    if project_root ~= root then
      return {}
    end
    return vim.deepcopy(definitions)
  end,
})
local panel = controller:open(root)
local orders = runtime:get(definitions[1].key)
local auth = runtime:get(definitions[2].key)

local function header()
  return vim.api.nvim_eval_statusline(vim.wo[panel.output_win].winbar, {
    winid = panel.output_win,
    use_winbar = true,
    maxwidth = vim.api.nvim_win_get_width(panel.output_win),
  }).str
end

local function selected_mark(service)
  local marks = vim.api.nvim_buf_get_extmarks(panel.list_bufnr, panel.selection_namespace, 0, -1, { details = true })
  assert_equal(1, #marks, "exactly one row should identify the displayed log")
  local mark = marks[1]
  assert_equal(service.key, panel.rows[mark[2] + 1], "selection should identify the displayed service")
  assert_equal("ServicesSelected", mark[4].line_hl_group, "selection should fill the entire row")
  return mark[4]
end

assert_equal(auth.key, panel.focused_key, "first opening should display the first service when nothing was remembered")
assert(header():find(auth.name, 1, true), "the initial log should identify its service")
orders.status = "RUNNING"
auth.status = "RUNNING"
controller:render(panel)
assert(controller:focus(panel, orders.key))
assert_equal(false, vim.wo[panel.list_win].cursorline, "persistent selection should replace the transient cursor line")
local mark = selected_mark(orders)
assert_equal("▸", mark.virt_text[1][1], "selection should have a non-color marker")
assert_equal("overlay", mark.virt_text_pos, "the marker should preserve existing status and name alignment")
assert(header():find(orders.name, 1, true), "the log header should repeat the selected service name")
assert(not header():find(auth.name, 1, true), "the log header should not identify another service")
assert(header():find(":8000", 1, true), "the log header should include the displayed service's ready port")
assert(header():find("[FOLLOW]", 1, true), "the log header should retain follow mode")

local selection = vim.api.nvim_get_hl(0, { name = "ServicesSelected", link = false })
assert_equal(0x243656, selection.bg, "selection should use the theme's selected surface")
assert_equal(true, selection.bold, "selection should emphasize the service name")
assert_equal(nil, selection.fg, "selection should preserve semantic status and port colors")
assert_equal(17, selection.ctermbg, "selection should retain terminal color support")
assert_equal(
  selection.bg,
  vim.api.nvim_get_hl(0, { name = "ServicesLogBar", link = false }).bg,
  "the log header and selected row should share a surface"
)
assert_equal(
  0x5D9BEB,
  vim.api.nvim_get_hl(0, { name = "ServicesSelectionMarker", link = false }).fg,
  "selection should use a different visual role from running green"
)
vim.api.nvim_set_current_win(panel.output_win)
selected_mark(orders)
assert(header():find(orders.name, 1, true), "moving into the log should preserve its source")

local list_changedtick = vim.api.nvim_buf_get_changedtick(panel.list_bufnr)
vim.api.nvim_set_current_win(panel.list_win)
for row, key in ipairs(panel.rows) do
  if key == auth.key then
    vim.api.nvim_win_set_cursor(panel.list_win, { row, 0 })
    break
  end
end
vim.api.nvim_exec_autocmds("CursorMoved", { buffer = panel.list_bufnr, modeline = false })
selected_mark(auth)
assert(header():find(auth.name, 1, true), "cursor selection should update log identity immediately")
assert_equal(
  auth.output.bufnr,
  vim.api.nvim_win_get_buf(panel.output_win),
  "the header should identify the actual buffer"
)
assert_equal(
  list_changedtick,
  vim.api.nvim_buf_get_changedtick(panel.list_bufnr),
  "selecting should not rewrite list lines"
)

assert(controller:focus(panel, orders.key))
local log_lines = {}
for index = 1, 40 do
  log_lines[index] = "orders log " .. index
end
runtime:append_output(orders.key, "stdout", table.concat(log_lines, "\n") .. "\n")
assert(
  vim.wait(500, function()
    return vim.api.nvim_buf_line_count(orders.output.bufnr) >= 40
  end),
  "log fixture should render"
)
list_changedtick = vim.api.nvim_buf_get_changedtick(panel.list_bufnr)
vim.api.nvim_set_current_win(panel.output_win)
vim.api.nvim_win_set_cursor(panel.output_win, { 1, 0 })
vim.api.nvim_exec_autocmds("CursorMoved", { buffer = orders.output.bufnr, modeline = false })
runtime:append_output(orders.key, "stdout", "unread line\n")
assert(
  vim.wait(500, function()
    return panel.output_states[orders.key].unseen_lines == 1
  end),
  "paused logs should count unread output"
)
assert(header():find(orders.name, 1, true), "pausing should retain the service identity")
assert(header():find("PAUSED", 1, true), "pausing should remain visible")
assert(header():find("1 new", 1, true), "paused mode should retain the unread count")
selected_mark(orders)
assert_equal(
  list_changedtick,
  vim.api.nvim_buf_get_changedtick(panel.list_bufnr),
  "log output should not rewrite list lines"
)

orders.name = "订单服务%{1+1}MossServiceCommonServerApplication"
controller:render(panel)
assert(header():find(orders.name, 1, true), "service names should be literal, including statusline syntax")
vim.api.nvim_win_set_width(panel.list_win, 140)
vim.api.nvim_exec_autocmds("WinResized", { modeline = false })
local narrow_header = header()
assert(narrow_header:find("订单服务", 1, true), "narrow headers should retain a readable service identity")
assert(narrow_header:find("…", 1, true), "truncated identities should use an ellipsis")
assert(narrow_header:find("PAUSED", 1, true), "narrow headers should retain the output mode")
assert_equal(panel.output_win, vim.api.nvim_get_current_win(), "resizing should not steal log focus")
selected_mark(orders)

vim.api.nvim_win_set_width(panel.list_win, 190)
vim.api.nvim_exec_autocmds("WinResized", { modeline = false })
assert(vim.fn.strdisplaywidth(header()) <= vim.api.nvim_win_get_width(panel.output_win), "tiny headers should fit")
assert(header():find("订", 1, true), "tiny headers should prioritize service identity over secondary controls")

vim.api.nvim_win_set_width(panel.list_win, 50)
vim.api.nvim_exec_autocmds("WinResized", { modeline = false })
orders.name = definitions[1].name
orders.status = "DEBUGGING"
local terminal_bufnr = vim.api.nvim_create_buf(false, true)
runtime:replace_output(orders.key, terminal_bufnr, { terminal = true })
assert(
  vim.wait(500, function()
    return vim.api.nvim_win_get_buf(panel.output_win) == terminal_bufnr
  end),
  "terminal replacement should display in the existing output split"
)
assert(header():find(orders.name, 1, true), "debug terminals should retain the service identity")
assert(header():find("debugging", 1, true), "debug terminals should show debugging status")
assert(header():find("TERMINAL", 1, true), "terminal output should identify its mode without a follow claim")
assert(not header():find("FOLLOW", 1, true), "terminal output should not advertise normal log follow")
selected_mark(orders)
runtime:archive_terminal_output(orders.key, terminal_bufnr)
assert(
  vim.wait(500, function()
    return vim.api.nvim_win_get_buf(panel.output_win) == orders.output.bufnr
  end),
  "archiving a terminal should restore normal logs"
)
assert(header():find(orders.name, 1, true), "archived logs should keep their service identity")

vim.api.nvim_set_hl(0, "Normal", { fg = "#151618", bg = "#FFFFFF" })
vim.api.nvim_set_hl(0, "TabLineSel", { fg = "#151618", bg = "#E4EBFC", ctermbg = 189 })
vim.api.nvim_set_hl(0, "DiagnosticSignInfo", { fg = "#3574D6", ctermfg = 25 })
vim.api.nvim_exec_autocmds("ColorScheme", { pattern = "services-identity-light", modeline = false })
selection = vim.api.nvim_get_hl(0, { name = "ServicesSelected", link = false })
assert_equal(0xE4EBFC, selection.bg, "persistent selection should adapt to light themes")
assert_equal(189, selection.ctermbg, "theme changes should update terminal selection colors")
assert_equal(
  selection.bg,
  vim.api.nvim_get_hl(0, { name = "ServicesLogBar", link = false }).bg,
  "theme changes should preserve the source/header association"
)
selected_mark(orders)
assert(header():find(orders.name, 1, true), "theme changes should retain the source header")

controller:close()
panel = controller:open(root)
selected_mark(orders)
assert(header():find(orders.name, 1, true), "reopening should restore both the selected marker and source header")
orders.status = "STOPPED"
runtime:dispose(orders.key)
assert(
  vim.wait(500, function()
    return panel.focused_key == nil and vim.api.nvim_win_get_buf(panel.output_win) == panel.empty_output
  end),
  "removing the displayed service should clear its output"
)
assert(not header():find(orders.name, 1, true), "removal should not retain a stale source header")
assert(header():find("No service selected", 1, true), "empty output should explain the missing selection")
assert_equal(
  0,
  #vim.api.nvim_buf_get_extmarks(panel.list_bufnr, panel.selection_namespace, 0, -1, {}),
  "removal should clear the old selected marker"
)

assert(controller:focus(panel, auth.key))
panel = controller:open("/empty-identity-project")
assert_equal(
  panel.empty_output,
  vim.api.nvim_win_get_buf(panel.output_win),
  "changing projects should clear stale logs"
)
assert(not header():find(auth.name, 1, true), "changing projects should clear stale identity")
controller:close()
auth.status = "STOPPED"
runtime:dispose(auth.key)
vim.api.nvim_buf_delete(terminal_bufnr, { force = true })
print("services-panel-identity-tests: ok")
