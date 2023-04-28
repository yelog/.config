return {
	{
		"akinsho/bufferline.nvim",
		-- version > v3.5.0 close icon will not show
		-- version = "v3.5.0",
		dependencies = { "nvim-tree/nvim-web-devicons", version = "*" },
		config = function()
			vim.opt.termguicolors = true
			local bufferline = require("bufferline")
			bufferline.setup({
				options = {
					mode = "buffers", -- set to "tabs" to only show tabpages instead
					buffer_close_icon = "",
					-- modified_icon = "●",
					-- close_icon = "",
					-- left_trunc_marker = "",
					-- right_trunc_marker = "",
					offsets = {
						{ filetype = "NvimTree", text = "", padding = 1 },
						{ filetype = "neo-tree", text = "", padding = 1 },
						{ filetype = "Outline", text = "", padding = 1 },
					},
					separator_style = "thick",
					-- hover = {
					-- 	enabled = true,
					-- 	delay = 200,
					-- 	reveal = { "close" },
					-- },
					indicator = {
						icon = "", -- this should be omitted if indicator style is not 'icon'
						style = "underline",
					},
					-- diagnostics = "nvim_lsp",
					max_name_length = 14,
					max_prefix_length = 13,
					tab_size = 20,
				},
			})
		end,
	},
	"moll/vim-bbye", -- bdelete has problem, so use this
}