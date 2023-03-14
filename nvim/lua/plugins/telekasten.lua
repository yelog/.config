return {
  "renerocksai/telekasten.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "renerocksai/calendar-vim",
  },
  config = function()
    require("telekasten").setup({
      home = vim.fn.expand("/Users/y/Library/Mobile Documents/iCloud~md~obsidian/Documents"), -- Put the name of your notes directory here
    })
  end,
}
