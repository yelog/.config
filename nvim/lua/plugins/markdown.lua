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
  -- {
  --   "yelog/markdown-preview.nvim",
  --   -- When dev is true, This plugin will use {config.dev.path}/markdown-preview.nvim/ instead of fetching it from GitHub https://lazy.folke.io/spec/examples
  --   -- {config.dev.path} configed by lazy.nvim in init.lua
  --   dev = true,
  --   -- dir = "/Users/yelog/workspace/lua/markdown-preview.nvim",
  -- },
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function()
      vim.fn["mkdp#util#install"]()
      -- vim.g.mkdp_theme = 'light'
      vim.cmd([[ let g:mkdp_theme = 'light' ]])
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
        "swift", "javascript" }
    end,
  }, --> syntax highlighting and filetype plugins for Markdown
  {
    "lukas-reineke/headlines.nvim",
    dependencies = "nvim-treesitter/nvim-treesitter",
    opts = function()
      -- local opts = {}
      -- for _, ft in ipairs({ "markdown", "norg", "rmd", "org" }) do
      --   opts[ft] = {
      --     headline_highlights = {},
      --     -- disable bullets for now. See https://github.com/lukas-reineke/headlines.nvim/issues/66
      --     bullets = {},
      --     quote_string = false,
      --   }
      --   for i = 1, 6 do
      --     local hl = "Headline" .. i
      --     vim.api.nvim_set_hl(0, hl, { link = "Headline", default = true })
      --     table.insert(opts[ft].headline_highlights, hl)
      --   end
      -- end
      -- return opts
    end,
    ft = { "markdown", "norg", "rmd", "org" },
    config = function(_, opts)
      -- PERF: schedule to prevent headlines slowing down opening a file
      -- vim.schedule(function()
      --   require("headlines").setup(opts)
      --   require("headlines").refresh()
      -- end)
      require("headlines").setup {
        markdown = {
          query = vim.treesitter.query.parse(
            "markdown",
            [[
                (atx_heading [
                    (atx_h1_marker)
                    (atx_h2_marker)
                    (atx_h3_marker)
                    (atx_h4_marker)
                    (atx_h5_marker)
                    (atx_h6_marker)
                ] @headline)

                (thematic_break) @dash

                (fenced_code_block) @codeblock

                (block_quote_marker) @quote
                (block_quote (paragraph (inline (block_continuation) @quote)))
                (block_quote (paragraph (block_continuation) @quote))
                (block_quote (block_continuation) @quote)
                 [
                  (list_marker_minus)
                  (list_marker_star)
                  (list_marker_plus)
                ] @list_marker
            ]]
          ),
          headline_highlights = { "Headline" },
          bullet_highlights = {
            "@text.title.1.marker.markdown",
            "@text.title.2.marker.markdown",
            "@text.title.3.marker.markdown",
            "@text.title.4.marker.markdown",
            "@text.title.5.marker.markdown",
            "@text.title.6.marker.markdown",
          },
          -- disable bullets for now. See https://github.com/lukas-reineke/headlines.nvim/issues/66
          bullets = {},
          -- bullets = { "◉", "○", "✸", "✿" },
          codeblock_highlight = "CodeBlock",
          dash_highlight = "Dash",
          dash_string = "-",
          quote_highlight = "Quote",
          quote_string = "┃",
          fat_headlines = true,
          fat_headline_upper_string = "▃",
          fat_headline_lower_string = "🬂",
          list_marker_string = "•",
        },
        rmd = {
          query = vim.treesitter.query.parse(
            "markdown",
            [[
                (atx_heading [
                    (atx_h1_marker)
                    (atx_h2_marker)
                    (atx_h3_marker)
                    (atx_h4_marker)
                    (atx_h5_marker)
                    (atx_h6_marker)
                ] @headline)

                (thematic_break) @dash

                (fenced_code_block) @codeblock

                (block_quote_marker) @quote
                (block_quote (paragraph (inline (block_continuation) @quote)))
                (block_quote (paragraph (block_continuation) @quote))
                (block_quote (block_continuation) @quote)
            ]]
          ),
          treesitter_language = "markdown",
          headline_highlights = { "Headline" },
          bullet_highlights = {
            "@text.title.1.marker.markdown",
            "@text.title.2.marker.markdown",
            "@text.title.3.marker.markdown",
            "@text.title.4.marker.markdown",
            "@text.title.5.marker.markdown",
            "@text.title.6.marker.markdown",
          },
          bullets = { "◉", "○", "✸", "✿" },
          codeblock_highlight = "CodeBlock",
          dash_highlight = "Dash",
          dash_string = "-",
          quote_highlight = "Quote",
          quote_string = "┃",
          fat_headlines = true,
          fat_headline_upper_string = "▃",
          fat_headline_lower_string = "🬂",
        },
      }
    end,
  },
}
