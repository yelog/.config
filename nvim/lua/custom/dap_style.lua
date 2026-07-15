local M = {}

local signs = {
  DapBreakpoint = { text = "●", hl = "DapBreakpoint" },
  DapBreakpointCondition = { text = "◆", hl = "DapBreakpointCondition" },
  DapBreakpointRejected = { text = "×", hl = "DapBreakpointRejected" },
  DapLogPoint = { text = "◌", hl = "DapLogPoint" },
  DapStopped = { text = "▶", hl = "DapStopped", linehl = "DapStoppedLine" },
}

function M.apply_highlights(highlights, colors)
  local blend = require("tokyonight.util").blend
  highlights.DapBreakpoint = { fg = colors.red, bold = true }
  highlights.DapBreakpointCondition = { fg = colors.orange, bold = true }
  highlights.DapBreakpointRejected = { fg = colors.red1, bold = true }
  highlights.DapLogPoint = { fg = colors.blue, bold = true }
  highlights.DapStopped = { fg = colors.yellow, bold = true }
  highlights.DapStoppedLine = { bg = blend(colors.yellow, 0.18, colors.bg) }
end

function M.apply_signs()
  for name, sign in pairs(signs) do
    vim.fn.sign_define(name, {
      text = sign.text,
      texthl = sign.hl,
      numhl = sign.hl,
      linehl = sign.linehl or "",
    })
  end
end

return M
