return {
  "stevearc/conform.nvim",
  cmd = { "ConformInfo" },
  opts = function()
    return require("custom.format").config()
  end,
}
