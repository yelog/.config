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
vim.o.list = true
vim.api.nvim_set_hl(0, "DiagnosticOk", { fg = "#6AAA73", ctermfg = 2 })
vim.api.nvim_set_hl(0, "DiagnosticInfo", { fg = "#6F737A" })
vim.api.nvim_set_hl(0, "DiagnosticSignInfo", { fg = "#5D9BEB" })

local root = "/panel-style-project"
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
      return "dev"
    end,
  },
  discover = function()
    return vim.deepcopy(definitions)
  end,
})
local panel = controller:open(root)
assert_equal(false, vim.wo[panel.list_win].list, "status padding should not show whitespace markers")
local orders = runtime:get(definitions[1].key)
local auth = runtime:get(definitions[2].key)

local function row_for(service)
  for index, key in ipairs(panel.rows) do
    if key == service.key then
      return vim.api.nvim_buf_get_lines(panel.list_bufnr, index - 1, index, false)[1], index - 1
    end
  end
  error("missing service row")
end

local function highlighted_text(service, group)
  local line, row = row_for(service)
  local marks = vim.api.nvim_buf_get_extmarks(
    panel.list_bufnr,
    panel.namespace,
    { row, 0 },
    { row, -1 },
    { details = true }
  )
  for _, mark in ipairs(marks) do
    if mark[4].hl_group == group then
      return line:sub(mark[3] + 1, mark[4].end_col)
    end
  end
end

orders.status = "RUNNING"
auth.status = "RUNNING"
controller:render(panel)
local line = row_for(orders)
assert(line:find("●", 1, true), "ready services should use a solid running indicator")
assert_equal(
  ":8000",
  highlighted_text(orders, "ServicesReadyPort"),
  "ready ports should have a dedicated success highlight"
)
assert_equal(
  "",
  highlighted_text(orders, "String"),
  "the provider highlight should cover the full icon after the multibyte status symbol"
)
local port_highlight = vim.api.nvim_get_hl(0, { name = "ServicesReadyPort", link = false })
assert_equal(0x6AAA73, port_highlight.fg, "ports should use the theme success color instead of info gray")
assert_equal(true, port_highlight.bold, "ready ports should be bold")
assert_equal(2, port_highlight.ctermfg, "ready ports should preserve terminal color support")
assert_equal(nil, port_highlight.bg, "port emphasis should preserve the selected-row background")
local width = vim.api.nvim_win_get_width(panel.list_win)
for _, service in ipairs({ orders, auth }) do
  local service_line = row_for(service)
  assert_equal(width, vim.fn.strdisplaywidth(service_line), "service details should align to the right edge")
  assert(service_line:match(":%d+ $"), "ports should retain a one-cell right margin")
end

local states = {
  { status = "RUNNING", ready = false, symbol = "◔", detail = "starting" },
  { status = "STARTING", ready = false, symbol = "◔", detail = "starting" },
  { status = "STOPPING", ready = true, symbol = "◒", detail = "stopping" },
  { status = "RESTART_PENDING", ready = false, symbol = "◒", detail = "restarting" },
  { status = "FAILED", ready = true, symbol = "×", detail = "failed" },
  { status = "DEBUGGING", ready = true, symbol = "◆", detail = "debugging" },
  { status = "STOPPED", ready = true, symbol = "○", detail = "stopped" },
}
for _, state in ipairs(states) do
  orders.status = state.status
  orders.metadata.ready = state.ready
  controller:render(panel)
  local state_line = row_for(orders)
  assert_equal(
    state.symbol,
    vim.fn.strcharpart(state_line, 1, 1),
    state.status .. " should remain distinguishable without color"
  )
  assert(state_line:find(state.detail, 1, true), state.status .. " should show its status text")
  assert(not state_line:find(":8000", 1, true), state.status .. " should not advertise a ready port")
end

orders.status = "RUNNING"
orders.metadata.ready = true
orders.metadata.port = nil
controller:render(panel)
assert_equal(
  "ready",
  highlighted_text(orders, "ServicesReadyPort"),
  "ready services without a detected port should retain success emphasis"
)
orders.metadata.port = 8000
orders.name = "订单服务MossServiceCommonServerApplication"
assert(controller:focus(panel, orders.key))
vim.api.nvim_win_set_width(panel.list_win, 26)
vim.api.nvim_exec_autocmds("WinResized", { modeline = false })
line = row_for(orders)
assert_equal(26, vim.fn.strdisplaywidth(line), "resizing should fit rows by display width")
assert(line:find("订单", 1, true), "truncation should preserve complete multibyte characters")
assert(line:find("…", 1, true), "truncated service names should show an ellipsis")
assert(line:find(":8000", 1, true), "long names should not hide ready ports")
assert_equal(
  ":8000",
  highlighted_text(orders, "ServicesReadyPort"),
  "port byte offsets should remain correct with multibyte service names"
)
assert_equal(orders.key, panel.focused_key, "resizing should retain the selected service")
assert_equal(orders.output.bufnr, vim.api.nvim_win_get_buf(panel.output_win), "resizing should retain the selected log")

vim.api.nvim_set_current_win(panel.output_win)
vim.api.nvim_win_set_width(panel.list_win, 60)
vim.api.nvim_exec_autocmds("WinResized", { modeline = false })
line = row_for(orders)
assert_equal(60, vim.fn.strdisplaywidth(line), "expanding should re-align the status column")
assert(line:find(orders.name, 1, true), "expanding should restore the full service name")
assert_equal(panel.output_win, vim.api.nvim_get_current_win(), "resizing should not steal focus from logs")

vim.api.nvim_win_set_width(panel.list_win, 14)
vim.api.nvim_exec_autocmds("WinResized", { modeline = false })
line = row_for(orders)
assert_equal(14, vim.fn.strdisplaywidth(line), "compact lists should stay inside the visible width")
assert(line:find(":8000", 1, true), "compact lists should prioritize the ready port")

for _, compact_width in ipairs({ 12, 8, 2 }) do
  vim.api.nvim_win_set_width(panel.list_win, compact_width)
  vim.api.nvim_exec_autocmds("WinResized", { modeline = false })
  line = row_for(orders)
  assert_equal(compact_width, vim.fn.strdisplaywidth(line), "very narrow lists should avoid clipped rows")
  assert(line:find("●", 1, true), "very narrow lists should retain the running indicator")
  if compact_width >= 8 then
    assert_equal(":8000", highlighted_text(orders, "ServicesReadyPort"), "compact ports should stay highlighted")
  end
end

vim.api.nvim_set_hl(0, "DiagnosticOk", { fg = "#276B36", ctermfg = 22 })
vim.api.nvim_exec_autocmds("ColorScheme", { pattern = "services-test-light", modeline = false })
port_highlight = vim.api.nvim_get_hl(0, { name = "ServicesReadyPort", link = false })
assert_equal(0x276B36, port_highlight.fg, "service highlights should follow colorscheme changes")
assert_equal(true, port_highlight.bold, "theme changes should preserve port emphasis")
assert_equal(22, port_highlight.ctermfg, "theme changes should update terminal colors")
assert_equal(
  0x6F737A,
  vim.api.nvim_get_hl(0, { name = "DiagnosticInfo", link = false }).fg,
  "service presentation should not recolor global diagnostics"
)

controller:close()
orders.status = "STOPPED"
auth.status = "STOPPED"
runtime:dispose(orders.key)
runtime:dispose(auth.key)
print("services-panel-style-tests: ok")
