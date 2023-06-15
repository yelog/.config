return {
	"phaazon/hop.nvim",
	branch = "v2",
	config = function()
		-- place this in one of your configuration file(s)
		local hop = require("hop")
		hop.setup({
			keys = "etovxqpdygfblzhckisuran",
			jump_on_sole_occurrence = true,
		})
		vim.api.nvim_set_keymap("n", ",w", "<cmd>HopWord<cr>", { noremap = true, silent = true })
		vim.api.nvim_set_keymap("n", ",a", "<cmd>HopAnywhere<cr>", { noremap = true, silent = true })
		vim.api.nvim_set_keymap("n", ",s", "<cmd>HopChar2<cr>", { noremap = true, silent = true })
		vim.api.nvim_set_keymap("n", ",l", "<cmd>HopWordCurrentLineAC<cr>", { noremap = true, silent = true })
		vim.api.nvim_set_keymap("n", ",h", "<cmd>HopWordCurrentLineBC<cr>", { noremap = true, silent = true })
		vim.api.nvim_set_keymap("n", ",k", "<cmd>HopLineBC<cr>", { noremap = true, silent = true })
		vim.api.nvim_set_keymap("n", ",j", "<cmd>HopLineAC<cr>", { noremap = true, silent = true })
	end,
}
