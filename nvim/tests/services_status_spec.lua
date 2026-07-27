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

local status = require("services.status")

assert_equal(nil, status.summary({}, nil), "empty runtimes should not occupy the statusline")
assert_equal({ text = "○ 服务未运行", kind = "idle" }, status.summary({ { status = "STOPPED" } }, nil),
  "stopped services should show an idle state")
assert_equal({ text = "◔ 启动中 1", kind = "starting" }, status.summary({ { status = "STARTING" } }, nil),
  "starting services should show their count")
assert_equal({ text = "◔ 启动中 1", kind = "starting" }, status.summary({
  { status = "RUNNING", metadata = { ready = false } },
}, nil), "running processes should remain starting until their health check marks them ready")
assert_equal({ text = "● 运行中 2", kind = "running" }, status.summary({
  { status = "RUNNING", metadata = { ready = true } },
  { status = "DEBUGGING" },
}, nil), "running and debugging services should share the running count")
assert_equal({ text = "◒ 关闭中 1", kind = "stopping" }, status.summary({ { status = "STOPPING" } }, nil),
  "stopping services should remain visible until their process exits")
assert_equal({ text = "× 服务启动失败", kind = "failed" }, status.summary({ { status = "FAILED" } }, nil),
  "failed services should remain visible")
assert_equal({ text = "◒ 关闭中 1/2 · 0.1s", kind = "closing" }, status.summary({ { status = "RUNNING" } }, {
  phase = "closing",
  text = "◒ 关闭中 1/2 · 0.1s",
}), "shutdown feedback should take priority over runtime state")
assert_equal({ text = "! 正在强制关闭剩余服务", kind = "force" }, status.summary({}, {
  phase = "force",
  text = "! 正在强制关闭剩余服务",
}), "force-close feedback should be visible even after runtime cleanup")

print("services-status-tests: ok")
