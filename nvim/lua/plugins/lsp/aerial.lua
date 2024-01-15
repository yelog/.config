-- 显示文件结构 <leader>ts
return {
  "stevearc/aerial.nvim",
  config = function()
    require("aerial").setup({
      layout = {
        default_direction = "prefer_right",
        width = 50,
      },
    })
  end,
}
