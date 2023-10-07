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
