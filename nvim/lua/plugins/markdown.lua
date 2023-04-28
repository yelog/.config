return {
	{
		"dhruvasagar/vim-table-mode",
	}, --> table mode
	{
		"dkarter/bullets.vim",
		config = function()
			vim.g.bullets_enabled_file_types = { "markdown", "text", "gitcommit", "scratch" }
		end,
	}, --> list style
	{
		"suan/vim-instant-markdown",
		ft = "markdown",
		config = function()
			-- suan/vim-instant-markdown
			vim.g.instant_markdown_slow = 0
			vim.g.instant_markdown_autostart = 0
			vim.g.instant_markdown_autoscroll = 1
		end,
	}, --> automatically highlighting other uses of the word under the cursor
	{
		"tenxsoydev/vim-markdown-checkswitch",
		config = function()
			vim.g.md_checkswitch_style = "cycle"
		end,
	}, --> checkbox shortcut
	{
		"tpope/vim-markdown",
		config = function()
			-- tpope/vim-markdown
			vim.g.markdown_syntax_conceal = 0
			vim.g.markdown_fenced_languages =
				{ "html", "python", "bash=sh", "json", "java", "js=javascript", "sql", "yaml", "Dockerfile" }
		end,
	}, --> syntax highlighting and filetype plugins for Markdown
}
