return {
	-- 目前自带的 lsp.formatter 满足需求
	"nvimdev/guard.nvim",
	config = function()
		local ft = require("guard.filetype")
		ft("lua"):fmt("stylua")
		ft("json"):fmt("jq")
		ft("html", "javascript", "typescript", "css", "scss"):fmt("prettier")
		-- Call setup() LAST!
		require("guard").setup({
			-- the only options for the setup function
			fmt_on_save = false,
			-- Use lsp if no formatter was defined for this filetype
			lsp_as_default_formatter = true,
		})
	end,
}
