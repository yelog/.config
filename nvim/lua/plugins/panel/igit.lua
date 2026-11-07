return {
  "yelog/igit.nvim",
  dev = true,
  lazy = false, -- Register the interactive :igit abbreviation at startup.
  keys = {
    {
      "<leader>gi",
      function()
        require("igit").open()
      end,
      desc = "IGit",
    },
    {
      "<leader>gI",
      function()
        require("igit").open("log", { file = "%" })
      end,
      desc = "IGit Current File History",
    },
  },
  opts = {
    command = vim.fn.expand("~/.local/bin/igit"),
    command_alias = true,
    window = {
      layout = "float", -- "float", "left", "right", "bottom", "tab"
      width = 0.9,
      height = 0.85,
      border = "rounded",
    },
  },
}
