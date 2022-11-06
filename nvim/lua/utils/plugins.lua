vim.cmd [[packadd packer.nvim]]
-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
  return
end

return packer.startup(function()
  use 'wbthomason/packer.nvim' -- Package manager
  -------------- LSP --------------
  use 'neovim/nvim-lspconfig' -- Configurations for Nvim LSP
  use { 'hrsh7th/nvim-cmp' }
  -- use { 'hrsh7th/cmp-buffer' }
  use { 'hrsh7th/cmp-nvim-lsp' }
  -- use { 'hrsh7th/cmp-cmdline' } -- use to command/search complete

  -- use { 'hrsh7th/cmp-vsnip' }
  -- use { 'hrsh7th/vim-vsnip' }
  -- use { 'L3MON4D3/LuaSnip' }
  -- use { 'saadparwaiz1/cmp_luasnip' }

  use { 'jose-elias-alvarez/null-ls.nvim' }

  use "nvim-lua/plenary.nvim" -- Useful lua functions used ny lots of plugins
  use "nvim-lua/popup.nvim"
  use "folke/neodev.nvim"


  -- window
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
    requires = { {'nvim-lua/plenary.nvim'} }
  }
  use { 'wellle/tmux-complete.vim' }
  use { 'ellisonleao/gruvbox.nvim' }
  use {
    'nvim-lualine/lualine.nvim',
    requires = { 'kyazdani42/nvim-web-devicons', opt = true }
  }
  use {
    'akinsho/bufferline.nvim',
    tag = "v3.*",
    requires = 'kyazdani42/nvim-web-devicons'
  }
  use { 'rrethy/vim-hexokinase', run = 'make hexokinase' }  -- show color by color code
  use { 'RRethy/vim-illuminate' } -- automatically highlighting other uses of the word under the cursor
  use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' } -- automatically highlighting other uses of the word under the cursor
  -------------- markdown --------------
  use { 'suan/vim-instant-markdown', ft = 'markdown' } -- automatically highlighting other uses of the word under the cursor
  use { 'dhruvasagar/vim-table-mode' }
  use { 'dkarter/bullets.vim' }
  use { 'tpope/vim-markdown' }
  use { 'tenxsoydev/vim-markdown-checkswitch' }
  use { 'gelguy/wilder.nvim' }
end)