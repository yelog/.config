vim.o.background = "dark" -- or "light" for light mode
require("gruvbox").setup({
	undercurl = true,
	underline = true,
	bold = true,
	italic = true,
	strikethrough = true,
	invert_selection = false,
	invert_signs = false,
	invert_tabline = false,
	invert_intend_guides = false,
	inverse = true, -- invert background for search, diffs, statuslines and errors
	contrast = "", -- can be "hard", "soft" or empty string
	overrides = {
		markdownH1 = { fg = "#F99417" },
		markdownH2 = { fg = "#FFED00" },
		markdownH3 = { fg = "#16FF00" },
		markdownH4 = { fg = "#30E3DF" },
	},
	dim_inactive = false,
	transparent_mode = false,
	palette_overrides = {
		-- bright_green = "#C58940"
	},
})
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
		sidebars = "dark", -- style for sidebars, see below
		floats = "dark", -- style for floating windows
	},
	sidebars = { "qf", "help" }, -- Set a darker background on sidebar-like windows. For example: `["qf", "vista_kind", "terminal", "packer"]`
	day_brightness = 0.3, -- Adjusts the brightness of the colors of the **Day** style. Number between 0 and 1, from dull to vibrant colors
	hide_inactive_statusline = false, -- Enabling this option, will hide inactive statuslines and replace them with a thin border instead. Should work with the standard **StatusLine** and **LuaLine**.
	dim_inactive = false, -- dims inactive windows
	lualine_bold = false, -- When `true`, section headers in the lualine theme will be bold

	--- You can override specific color groups to use other groups or a hex color
	--- function will be called with a ColorScheme table
	---@param colors ColorScheme
	on_colors = function(colors) end,

	--- You can override specific highlights to use other groups or a hex color
	--- function will be called with a Highlights and ColorScheme table
	---@param highlights Highlights
	---@param colors ColorScheme
	on_highlights = function(highlights, colors)
		highlights.markdownH1 = { fg = "#F99417" }
		highlights.markdownH2 = { fg = "#FFED00" }
		highlights.markdownH3 = { fg = "#16FF00" }
		highlights.markdownH4 = { fg = "#30E3DF" }
		highlights.markdownH1Delimiter = { fg = highlights.markdownH1.fg }
		highlights.markdownH2Delimiter = { fg = highlights.markdownH2.fg }
		highlights.markdownH3Delimiter = { fg = highlights.markdownH3.fg }
		highlights.markdownH4Delimiter = { fg = highlights.markdownH4.fg }
    highlights.Visual = { bg="#6D6BC8" }
	end,
})
-- vim.cmd([[colorscheme gruvbox]])
vim.cmd([[colorscheme tokyonight]])

--> custom color
vim.cmd([[highlight checkbox cterm=bold gui=bold guifg=#b16286]])
vim.cmd([[match checkbox /\v\[ \]/]])
vim.cmd([[highlight checkbox_checked cterm=bold gui=bold guifg=#3ac569]])
vim.cmd([[2match checkbox_checked /\v\[x\]/]])
vim.cmd([[hi tkLink ctermfg=Blue cterm=bold,underline guifg=blue gui=bold,underline]])
