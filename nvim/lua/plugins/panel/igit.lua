return {
  "yelog/igit.nvim",
  dev = true,
  lazy = false, -- Register the interactive :igit abbreviation at startup.
  keys = {
    {
      "<D-g>",
      function()
        local igit = require("igit")
        if not igit.close() then
          igit.open()
        end
      end,
      mode = { "n", "t" },
      desc = "Toggle IGit",
    },
    {
      "<leader>gi",
      function()
        require("igit").open()
      end,
      desc = "IGit",
    },
    {
      "<D-S-H>",
      function()
        require("igit").open("log", { file = "%" })
      end,
      mode = { "n", "i", "t" },
      desc = "IGit Current File History",
    },
  },
  opts = {
    command = vim.fn.expand("~/.local/bin/ig"),
    command_alias = true,
    window = {
      layout = "float", -- "float", "left", "right", "bottom", "tab"
      width = 0.9,
      height = 0.85,
      border = "rounded",
    },
  },
}
