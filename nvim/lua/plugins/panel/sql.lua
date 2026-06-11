return {
  "kopecmaciej/vi-sql.nvim",
  config = function()
    require("vi-sql").setup({
      -- Press this inside vi-sql to hide the window (change to taste)
      hide_key = "<C-q>",
    })
  end,
  cmd = { "ViSQL", "ViSQLJump" },
  keys = {
    { "<leader>vs", "<cmd>ViSQL<cr>", desc = "Open vi-sql" },
    -- { "<leader>vj", ":ViSQLJump ", desc = "vi-sql: jump to table", silent = false },
  },
}
