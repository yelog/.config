-- 显示文件结构 <leader>ts
return {
  "stevearc/aerial.nvim",
  branch = "nvim-0.11",
  -- Optional dependencies
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons"
  },
  config = function()
    require("aerial").setup({
      layout = {
        default_direction = "prefer_right",
        width = 50,
      },
    })
  end,
}
