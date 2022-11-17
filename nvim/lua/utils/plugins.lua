vim.cmd [[packadd packer.nvim]]
-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
  return
end

return packer.startup(function(use)
  use 'wbthomason/packer.nvim' -- Package manager
  -------------- lsp & complete --------------
  use 'neovim/nvim-lspconfig' -- Configurations for Nvim LSP
  use { 'hrsh7th/nvim-cmp' }
  use { 'hrsh7th/cmp-buffer' }
  use { 'hrsh7th/cmp-nvim-lsp' }
  use { 'andersevenrud/cmp-tmux' }
  use { 'hrsh7th/cmp-path' }
  use { 'hrsh7th/cmp-cmdline' } -- use to command/search complete
  use { 'lukas-reineke/cmp-rg' } -- use to command/search complete

  -- use { 'hrsh7th/cmp-vsnip' }
  -- use { 'hrsh7th/vim-vsnip' }
  -- use { 'L3MON4D3/LuaSnip' }
  -- use { 'saadparwaiz1/cmp_luasnip' }

  use { 'jose-elias-alvarez/null-ls.nvim' }

  use "nvim-lua/plenary.nvim" -- Useful lua functions used ny lots of plugins
  use "nvim-lua/popup.nvim"
  use "folke/neodev.nvim"

  -------------- tool --------------
  use {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v2.x",
    requires = {
      "nvim-lua/plenary.nvim",
      "kyazdani42/nvim-web-devicons", -- not strictly required, but recommended
      "MunifTanjim/nui.nvim",
    }
  }
  use {
    'nvim-telescope/telescope.nvim', tag = '0.1.0',
    requires = { { 'nvim-lua/plenary.nvim' } }
  }
  use {
    'akinsho/bufferline.nvim',
    tag = "v3.*",
    requires = 'kyazdani42/nvim-web-devicons'
  }
  use { 'rmagatti/auto-session' }
  use { 'phaazon/hop.nvim', branch = 'v2'}
  use {
    'numToStr/Comment.nvim',
    config = function()
      require('Comment').setup()
    end
  }
  use {
    'andymass/vim-matchup',
    setup = function()
      -- may set any options here
      vim.g.matchup_matchparen_offscreen = { method = "popup" }
    end
  }
  use { "folke/which-key.nvim" }
  use {
    'gcmt/wildfire.vim',
    config = function()
      vim.g.wildfire_objects = {"i'", 'i"', "i)", "i]", "i}", "ip", "it"}
    end
  }
  -------------- decoration --------------
  use { 'ellisonleao/gruvbox.nvim' }
  use {
    'nvim-lualine/lualine.nvim',
    requires = { 'kyazdani42/nvim-web-devicons', opt = true }
  }
  use { 'RRethy/vim-illuminate' } -- automatically highlighting other uses of the word under the cursor
  use { 'rrethy/vim-hexokinase', run = 'make hexokinase' } -- show color by color code
  use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' } -- automatically highlighting other uses of the word under the cursor
  use { 'dhruvasagar/vim-table-mode' } -- table mode
  use { 'dkarter/bullets.vim' } -- list style
  use { 'tpope/vim-markdown' } -- syntax highlighting and filetype plugins for Markdown
  use { 'tenxsoydev/vim-markdown-checkswitch' } -- checkbox
  use { 'suan/vim-instant-markdown', ft = 'markdown' } -- automatically highlighting other uses of the word under the cursor
end)
