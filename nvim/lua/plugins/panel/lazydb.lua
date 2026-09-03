return {
  "yelog/lazydb.nvim",
  cmd = {
    "LazyDB",
    "LazyDBToggle",
    "LazyDBHide",
    "LazyDBStop",
    "LazyDBRestart",
  },
  keys = {
    {
      "<leader>db",
      function()
        require("lazydb").toggle()
      end,
      desc = "Toggle LazyDB",
    },
  },
  opts = {
    executable = "lazydb",
    window = { width = 0.92, height = 0.90, border = "rounded" },
  },
}
