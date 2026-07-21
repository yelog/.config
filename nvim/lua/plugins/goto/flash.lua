-- 通过搜索字符的方式进行跳转
local function apply_jb_highlights()
  vim.api.nvim_set_hl(0, "FlashLabel", {
    fg = "#c8d3f5",
    bg = "#ff007c",
    bold = true,
  })
  vim.api.nvim_set_hl(0, "FlashMatch", {
    fg = "#c8d3f5",
    bg = "#3e68d7",
  })
  vim.api.nvim_set_hl(0, "FlashCurrent", {
    fg = "#1b1d2b",
    bg = "#ff966c",
  })
end

return {
  "folke/flash.nvim",
  event = "VeryLazy",
  ---@typ Flash.Config
  opts = {
    modes = {
      search = {
        enabled = false,
      }
    },
  },
  config = function(_, opts)
    require("flash").setup(opts)

    local group = vim.api.nvim_create_augroup("JBFlashHighlights", { clear = true })
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = group,
      pattern = "jb",
      callback = apply_jb_highlights,
    })

    if vim.g.colors_name == "jb" then
      apply_jb_highlights()
    end
  end,
  keys = {
    {
      "s",
      mode = { "n", "x", "o" },
      function()
        -- default options: exact mode, multi window, all directions, with a backdrop
        require("flash").jump()
      end,
      desc = "Flash",
    },
    {
      "S",
      mode = { "n", "o", "x" },
      function()
        require("flash").treesitter()
      end,
      desc = "Flash Treesitter",
    },
    {
      "r",
      mode = "o",
      function()
        require("flash").remote()
      end,
      desc = "Remote Flash",
    },
  },
}
