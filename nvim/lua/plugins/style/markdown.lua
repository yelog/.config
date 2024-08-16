return {
  {
    "dhruvasagar/vim-table-mode",
    config = function()
      vim.api.nvim_exec([[
        augroup markdown_config
          autocmd!
          autocmd FileType markdown TableModeEnable
          autocmd FileType markdown nnoremap <buffer> <M-s> :TableModeRealign<CR>
        augroup END
      ]], false)
      vim.g.table_mode_sort_map = '<leader>mts'
    end

  }, --> table mode
  {
    "dkarter/bullets.vim",
    config = function()
      vim.g.bullets_enabled_file_types = { "markdown", "text", "gitcommit", "scratch" }
    end,
  }, --> list style
  -- {
  --   "gaoDean/autolist.nvim",
  --   ft = {
  --     "markdown",
  --     "text",
  --     "tex",
  --     "plaintex",
  --     "norg",
  --   },
  --   config = function()
  --     require("autolist").setup()
  --
  --     vim.keymap.set("i", "<tab>", "<cmd>AutolistTab<cr>")
  --     vim.keymap.set("i", "<s-tab>", "<cmd>AutolistShiftTab<cr>")
  --     -- vim.keymap.set("i", "<c-t>", "<c-t><cmd>AutolistRecalculate<cr>") -- an example of using <c-t> to indent
  --     vim.keymap.set("i", "<CR>", "<CR><cmd>AutolistNewBullet<cr>")
  --     vim.keymap.set("n", "o", "o<cmd>AutolistNewBullet<cr>")
  --     vim.keymap.set("n", "O", "O<cmd>AutolistNewBulletBefore<cr>")
  --     vim.keymap.set("n", "<CR>", "<cmd>AutolistToggleCheckbox<cr><CR>")
  --     vim.keymap.set("n", "<C-r>", "<cmd>AutolistRecalculate<cr>")
  --
  --     -- cycle list types with dot-repeat
  --     vim.keymap.set("n", "<leader>cn", require("autolist").cycle_next_dr, { expr = true })
  --     vim.keymap.set("n", "<leader>cp", require("autolist").cycle_prev_dr, { expr = true })
  --
  --     -- if you don't want dot-repeat
  --     -- vim.keymap.set("n", "<leader>cn", "<cmd>AutolistCycleNext<cr>")
  --     -- vim.keymap.set("n", "<leader>cp", "<cmd>AutolistCycleNext<cr>")
  --
  --     -- functions to recalculate list on edit
  --     vim.keymap.set("n", ">>", ">><cmd>AutolistRecalculate<cr>")
  --     vim.keymap.set("n", "<<", "<<<cmd>AutolistRecalculate<cr>")
  --     vim.keymap.set("n", "dd", "dd<cmd>AutolistRecalculate<cr>")
  --     vim.keymap.set("v", "d", "d<cmd>AutolistRecalculate<cr>")
  --   end,
  -- },
  -- {
  --   "suan/vim-instant-markdown",
  --   ft = "markdown",
  --   config = function()
  --     -- need install: npm -g install instant-markdown-d
  --     -- suan/vim-instant-markdown
  --     vim.g.instant_markdown_slow = 0
  --     vim.g.instant_markdown_autostart = 0
  --     vim.g.instant_markdown_autoscroll = 1
  --   end,
  -- }, --> automatically highlighting other uses of the word under the cursor
  -- {
  --   'adelarsq/image_preview.nvim',
  --   event = 'VeryLazy',
  --   config = function()
  --     require("image_preview").setup()
  --   end
  -- },
  {
    "yelog/marklive.nvim",
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    lazy = true,
    ft = "markdown",
    -- When dev is true, This plugin will use {config.dev.path}/markdown-preview.nvim/ instead of fetching it from GitHub https://lazy.folke.io/spec/examples
    -- {config.dev.path} configed by lazy.nvim in init.lua
    dev = true,
    opts = {
      enable = true,
      -- show_mode = 'insert-line'
    }
  },
  -- {
  --   'MeanderingProgrammer/render-markdown.nvim',
  --   opts = {},
  --   dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' }, -- if you use the mini.nvim suite
  --   -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
  --   -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
  -- },
  -- {
  --   "OXY2DEV/markview.nvim",
  --   ft = "markdown",
  --     dev = true,
  --   dependencies = {
  --     -- You may not need this if you don't lazy load
  --     -- Or if the parsers are in your $RUNTIMEPATH
  --     "nvim-treesitter/nvim-treesitter",
  --
  --     "nvim-tree/nvim-web-devicons"
  --   },
  --   config = function()
  --     require("markview").setup({
  --       buf_ignore = { "nofile" },
  --       modes = { "n", "no" },
  --
  --       options = {
  --         on_enable = {},
  --         on_disable = {}
  --       },
  --
  --       -- block_quotes = {},
  --       -- checkboxes = {},
  --       -- code_blocks = {},
  --       -- headings = {},
  --       -- horizontal_rules = {},
  --       -- inline_codes = {},
  --       -- links = {},
  --       -- list_items = {},
  --       -- tables = {}
  --     });
  --   end
  -- },
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function()
      vim.fn["mkdp#util#install"]()
      vim.g.mkdp_theme = 'light'
      -- vim.cmd([[ let g:mkdp_theme = 'light' ]])
    end,
  },
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
      { "html", "python", "bash=sh", "json", "java", "js=javascript", "sql", "yaml", "xml", "Dockerfile", "Rust",
        "swift", "javascript", 'lua' }
    end,
  }, --> syntax highlighting and filetype plugins for Markdown
}
