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

package.preload["tokyonight.util"] = function()
  return {
    blend = function(foreground, alpha, background)
      return table.concat({ foreground, tostring(alpha), background }, ":")
    end,
  }
end

local dap_style = require("custom.dap_style")
local highlights = {}
dap_style.apply_highlights(highlights, {
  bg = "#1a1b26",
  red = "#f7768e",
  red1 = "#db4b4b",
  orange = "#ff9e64",
  blue = "#7aa2f7",
  yellow = "#e0af68",
})

assert_equal({ fg = "#f7768e", bold = true }, highlights.DapBreakpoint,
  "ordinary breakpoints should use the TokyoNight error color")
assert_equal({ fg = "#ff9e64", bold = true }, highlights.DapBreakpointCondition,
  "conditional breakpoints should use the TokyoNight warning color")
assert_equal({ fg = "#db4b4b", bold = true }, highlights.DapBreakpointRejected,
  "rejected breakpoints should use the muted error color")
assert_equal({ fg = "#7aa2f7", bold = true }, highlights.DapLogPoint,
  "log points should use the TokyoNight info color")
assert_equal({ fg = "#e0af68", bold = true }, highlights.DapStopped,
  "the stopped location should use the TokyoNight warning color")
assert_equal("#e0af68:0.18:#1a1b26", highlights.DapStoppedLine.bg,
  "the stopped location should have a low-saturation line background")

dap_style.apply_signs()
local expected_signs = {
  DapBreakpoint = { text = "●", hl = "DapBreakpoint" },
  DapBreakpointCondition = { text = "◆", hl = "DapBreakpointCondition" },
  DapBreakpointRejected = { text = "×", hl = "DapBreakpointRejected" },
  DapLogPoint = { text = "◌", hl = "DapLogPoint" },
  DapStopped = { text = "▶", hl = "DapStopped", linehl = "DapStoppedLine" },
}
for name, expected in pairs(expected_signs) do
  local sign = vim.fn.sign_getdefined(name)[1]
  assert(sign, name .. " should be defined")
  assert_equal(expected.text, vim.fn.strcharpart(sign.text, 0, 1), name .. " should use the expected glyph")
  assert_equal(expected.hl, sign.texthl, name .. " should use the expected sign highlight")
  assert_equal(expected.hl, sign.numhl, name .. " should use the expected number highlight")
  assert_equal(expected.linehl or "", sign.linehl or "", name .. " should use the expected line highlight")
end

print("dap-style-tests: ok")
