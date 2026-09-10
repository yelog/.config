return {
  "yelog/lazydb.nvim",
  dev = true,
  ft = { "sql", "xml" },
  cmd = {
    "LazyDB",
    "LazyDBToggle",
    "LazyDBHide",
    "LazyDBStop",
    "LazyDBRestart",
    "LazyDBLspRestart",
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
    -- executable = "lazydb",
    executable = "/Users/yelog/workspace/tui/lazydb/target/release/lazydb",
    profile = "lssc-uat",
    window = { width = 0.92, height = 0.90, border = "rounded" },
    lsp = {
      enabled = true,
      filetypes = { "sql", "xml" },
      diagnostics = {
        enabled = true,
        debounce_ms = 300,
      },
    },
  },
}
