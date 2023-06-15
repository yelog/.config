return {
  "folke/tokyonight.nvim",
  config = function()
    require("tokyonight").setup({
      -- your configuration comes here
      -- or leave it empty to use the default settings
      style = "night", -- The theme comes in three styles, `storm`, `moon`, a darker variant `night` and `day`
      light_style = "day", -- The theme is used when the background is set to light
      transparent = false, -- Enable this to disable setting the background color
      terminal_colors = true, -- Configure the colors used when opening a `:terminal` in Neovim
      styles = {
        -- Style to be applied to different syntax groups
        -- Value is any valid attr-list value for `:help nvim_set_hl`
        comments = { italic = true },
        keywords = { italic = true },
        functions = {},
        variables = {},
        -- Background styles. Can be "dark", "transparent" or "normal"
        sidebars = "normal", -- style for sidebars, see below
        floats = "dark", -- style for floating windows
      },
      sidebars = { "qf", "help" }, -- Set a darker background on sidebar-like windows. For example: `["qf", "vista_kind", "terminal", "packer"]`
      day_brightness = 0.3, -- Adjusts the brightness of the colors of the **Day** style. Number between 0 and 1, from dull to vibrant colors
      hide_inactive_statusline = false, -- Enabling this option, will hide inactive statuslines and replace them with a thin border instead. Should work with the standard **StatusLine** and **LuaLine**.
      dim_inactive = true, -- dims inactive windows
      lualine_bold = true, -- When `true`, section headers in the lualine theme will be bold

      --- You can override specific color groups to use other groups or a hex color
      --- function will be called with a ColorScheme table
      ---@param colors ColorScheme
      on_colors = function(colors)
        colors.border = "#ef9020"
      end,

      --- You can override specific highlights to use other groups or a hex color
      --- function will be called with a Highlights and ColorScheme table
      ---@param hl Highlights
      ---@param c ColorScheme
      on_highlights = function(hl, c)
        hl.markdownH1 = { fg = "#0081b4" }
        hl.markdownH2 = { fg = "#ef9020" }
        hl.markdownH3 = { fg = "#e990ab" }
        hl.markdownH4 = { fg = "#96cbb3" }
        hl.markdownH1Delimiter = { fg = hl.markdownH1.fg }
        hl.markdownH2Delimiter = { fg = hl.markdownH2.fg }
        hl.markdownH3Delimiter = { fg = hl.markdownH3.fg }
        hl.markdownH4Delimiter = { fg = hl.markdownH4.fg }
        hl.Visual = { bg = "#6D6BC8" }
        hl.markdownBold = { bold = true, fg = "#0081b4" }
      end,
    })
    vim.cmd([[colorscheme tokyonight]])
  end,
}
