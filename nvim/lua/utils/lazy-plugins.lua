local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- setup layz.nvim
require("lazy").setup({
	"folke/which-key.nvim",
	-------------- lsp & complete --------------
	"neovim/nvim-lspconfig", -- Configurations for Nvim LSP
	"williamboman/mason.nvim",
	"williamboman/mason-lspconfig.nvim",
	"ray-x/lsp_signature.nvim", -- Show function signature when you type
	"hrsh7th/nvim-cmp",
	"hrsh7th/cmp-buffer", -- nvim-cmp source for buffer words
	"hrsh7th/cmp-nvim-lsp",
	"andersevenrud/cmp-tmux", -- tmux completion source for nvim-cmp
	"hrsh7th/cmp-path", -- nvim-cmp source for filesystem paths
	"hrsh7th/cmp-cmdline", -- use to command/search complete
	"octaltree/cmp-look",
	"lukas-reineke/cmp-rg", -- ripgrep source for nvim-cmp
	"alvan/vim-closetag", -- when "<table|", type > , will be "<table>|</table>"
	"windwp/nvim-autopairs",
	"windwp/nvim-ts-autotag",
	"onsails/lspkind.nvim",
	-- "mfussenegger/nvim-jdtls",

	-- 'hrsh7th/cmp-vsnip',
	-- 'hrsh7th/vim-vsnip',
	"L3MON4D3/LuaSnip",
	-- 'saadparwaiz1/cmp_luasnip',

	"jose-elias-alvarez/null-ls.nvim",

	"nvim-lua/plenary.nvim", -- Useful lua functions used ny lots of plugins
	"nvim-lua/popup.nvim",
	"folke/neodev.nvim",

	{ "nvim-treesitter/nvim-treesitter" }, --> automatically highlighting other uses of the word under the cursor
	"nvim-treesitter/playground", --> automatically highlighting other uses of the word under the cursor
	-- use({ "edluffy/hologram.nvim" })
	--  Image Viewer as ASCII Art for Neovim written in Lua
	-- use({
	--   "samodostal/image.nvim",
	--   requires = {
	--     "nvim-lua/plenary.nvim",
	--   },
	-- })
	-- use({ "m00qek/baleia.nvim", tag = "v1.2.0" }) -->

	-- use({
	--   "abecodes/tabout.nvim",
	--   config = function()
	--     require("tabout").setup({
	--       tabkey = "<Tab>", -- key to trigger tabout, set to an empty string to disable
	--       backwards_tabkey = "<S-Tab>", -- key to trigger backwards tabout, set to an empty string to disable
	--       act_as_tab = true, -- shift content if tab out is not possible
	--       act_as_shift_tab = false, -- reverse shift content if tab out is not possible (if your keyboard/terminal supports <S-Tab>)
	--       default_tab = "<C-t>", -- shift default action (only at the beginning of a line, otherwise <TAB> is used)
	--       default_shift_tab = "<C-d>", -- reverse shift default action,
	--       enable_backwards = true, -- well ...
	--       completion = true, -- if the tabkey is used in a completion pum
	--       tabouts = {
	--         { open = "'", close = "'" },
	--         { open = '"', close = '"' },
	--         { open = "`", close = "`" },
	--         { open = "(", close = ")" },
	--         { open = "[", close = "]" },
	--         { open = "{", close = "}" },
	--       },
	--       ignore_beginning = true, --[[ if the cursor is at the beginning of a filled element it will rather tab out than shift the content ]]
	--       exclude = {}, -- tabout will ignore these filetypes
	--     })
	--   end,
	--   wants = { "nvim-treesitter" }, -- or require if not used so far
	--   after = { "nvim-cmp" }, -- if a completion plugin is using tabs load it before
	-- })
	{
		"folke/trouble.nvim",
		dependencies = { "kyazdani42/nvim-web-devicons" },
	},
	-------------- tool --------------
	{
		"nvim-neo-tree/neo-tree.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"kyazdani42/nvim-web-devicons", -- not strictly required, but recommended
			"MunifTanjim/nui.nvim",
		},
	},
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.0",
		dependencies = { "nvim-lua/plenary.nvim", "kdheepak/lazygit.nvim" },
	},
	{
		"akinsho/bufferline.nvim",
		dependencies = "kyazdani42/nvim-web-devicons",
	},
	-- use({ "rcarriga/nvim-notify" })
	{
		"folke/noice.nvim",
		config = function()
			require("noice").setup({
				-- add any options here
			})
		end,
		dependencies = {
			-- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
			"MunifTanjim/nui.nvim",
			-- OPTIONAL:
			--   `nvim-notify` is only needed, if you want to use the notification view.
			--   If not available, we use `mini` as the fallback
			"rcarriga/nvim-notify",
		},
	},
	"Pocco81/true-zen.nvim",
	"rmagatti/auto-session",
	{ "phaazon/hop.nvim", branch = "v2" },
	{
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
	},
	{
		"andymass/vim-matchup",
		init = function()
			-- may set any options here
			vim.g.matchup_matchparen_offscreen = { method = "popup" }
		end,
	},
	-- use({ "folke/which-key.nvim" })
	{
		"gcmt/wildfire.vim",
		init = function()
			vim.g.wildfire_objects = { "i'", 'i"', "i)", "i]", "i}", "ip", "it" }
		end,
	},
	"tpope/vim-surround", --> type ysiw' to wrap the word with '' or type cs'` to change 'word' to `word`
	"tpope/vim-repeat", --> repeat surround and so on
	"ybian/smartim", --> smart switch input method
	"itchyny/vim-cursorword", --> Underlines the word under the cursor
	"907th/vim-auto-save", --> auto-save
	"dhruvasagar/vim-open-url", --> open brower with the url under the cursor
	"airblade/vim-rooter", --> Changes Vim working directory to project root
	-- use({ -- chrome input use neovim
	--   "glacambre/firenvim",
	--   run = function()
	--     vim.fn["firenvim#install"](0)
	--   end,
	-- })
	-- use({
	--   "arnarg/todotxt.nvim",
	--   requires = { "MunifTanjim/nui.nvim" },
	-- })
	-------------- git --------------
	"airblade/vim-gitgutter",
	-- use({ "f-person/git-blame.nvim" })
	-------------- decoration --------------
	"ellisonleao/gruvbox.nvim",
	"folke/tokyonight.nvim",
	"stevearc/dressing.nvim",
	"lukas-reineke/indent-blankline.nvim", --> Indent guides for Neovim
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "kyazdani42/nvim-web-devicons" },
	},
	"RRethy/vim-illuminate", --> automatically highlighting other uses of the word under the cursor
	-- { ecrrethy/vim-hexokinase" }, --> show color by color code
	"jeffkreeftmeijer/vim-numbertoggle", --> Toggles between hybrid and absolute line numbers automatically
	-------------- markdown --------------
	"dhruvasagar/vim-table-mode", --> table mode
	"dkarter/bullets.vim", --> list style
	-- use({ "tpope/vim-markdown" }) --> syntax highlighting and filetype plugins for Markdown
	"godlygeek/tabular",
	"preservim/vim-markdown",
	"tenxsoydev/vim-markdown-checkswitch", --> checkbox shortcut
	{ "suan/vim-instant-markdown", ft = "markdown" }, --> automatically highlighting other uses of the word under the cursor
})
