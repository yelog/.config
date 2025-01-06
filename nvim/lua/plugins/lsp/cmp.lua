return {
  -- {
  --   "L3MON4D3/LuaSnip",
  --   dependencies = { "rafamadriz/friendly-snippets" },
  --   -- install jsregexp (optional!).
  --   build = "make install_jsregexp",
  --   config = function()
  --     -- require("luasnip").filetype_extend("ruby", { "rails" })
  --     require("luasnip.loaders.from_vscode").lazy_load {
  --       exclude = { "markdown" },
  --     }
  --     require("luasnip.loaders.from_snipmate").lazy_load()
  --   end,
  -- },
  -- {
  --   "hrsh7th/nvim-cmp",
  --   dependencies = {
  --     "luckasRanarison/tailwind-tools.nvim",
  --     "onsails/lspkind-nvim",
  --   },
  --   config = function()
  --     local cmp = require("cmp")
  --     local luasnip = require("luasnip")
  --     local compare = require("cmp.config.compare")
  --     local lspkind = require('lspkind')
  --
  --     cmp.setup({
  --       snippet = {
  --         -- REQUIRED - you must specify a snippet engine
  --         expand = function(args)
  --           -- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
  --           luasnip.lsp_expand(args.body) -- For `luasnip` users.
  --           -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
  --           -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
  --         end,
  --       },
  --       window = {
  --         documentation = false,
  --         -- documentation = {
  --         --   border = "rounded",
  --         --   winhighlight = "NormalFloat:Pmenu,NormalFloat:Pmenu,CursorLine:PmenuSel,Search:None",
  --         -- },
  --         completion = {
  --           border = "rounded",
  --           winhighlight = "NormalFloat:Pmenu,NormalFloat:Pmenu,CursorLine:PmenuSel,Search:None",
  --         },
  --       },
  --       experimental = {
  --         ghost_text = true,
  --       },
  --       mapping = cmp.mapping.preset.insert({
  --         -- ['<C-b>'] = cmp.mapping.scroll_docs(-4),
  --         -- ['<C-f>'] = cmp.mapping.scroll_docs(4),
  --         -- ['<Tab>'] = cmp.mapping.complete(),
  --         -- ['<C-e>'] = cmp.mapping.abort(),
  --         ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
  --         ["<Tab>"] = cmp.mapping(function(fallback)
  --           if cmp.visible() then
  --             cmp.select_next_item()
  --           elseif luasnip.jumpable(1) then
  --             luasnip.jump(1)
  --           elseif luasnip.expand_or_jumpable() then
  --             luasnip.expand_or_jump()
  --           elseif luasnip.expandable() then
  --             luasnip.expand()
  --           else
  --             fallback()
  --           end
  --         end, {
  --           "i",
  --           "s",
  --         }),
  --         ["<S-Tab>"] = cmp.mapping(function(fallback)
  --           if cmp.visible() then
  --             cmp.select_prev_item()
  --           elseif luasnip.jumpable(-1) then
  --             luasnip.jump(-1)
  --           else
  --             fallback()
  --           end
  --         end, {
  --           "i",
  --           "s",
  --         }),
  --       }),
  --       sources = cmp.config.sources({
  --         {
  --           name = "nvim_lsp",
  --           filter = function(entry, ctx)
  --             local kind = require("cmp.types.lsp").CompletionItemKind[entry:get_kind()]
  --             if kind == "Snippet" then
  --               return true
  --             end
  --
  --             if kind == "Text" then
  --               return true
  --             end
  --           end,
  --           group_index = 2,
  --         },
  --         { name = "luasnip", group_index = 2 }, -- For luasnip users
  --         {
  --           name = "buffer",
  --           group_index = 2,
  --         }, -- For buffer words
  --         -- { name = "tmux", group_index = 2 }, -- For tmux words
  --         -- { name = 'vsnip' }, -- For vsnip users
  --         { name = "path" }, -- For filesystem paths
  --         -- { name = "rg" }, -- For filesystem paths
  --         -- { name = 'ultisnips' }, -- For ultisnips users
  --         -- { name = 'snippy' }, -- For snippy users
  --         -- { name = "marksman" },
  --         -- { name = "tsserver" },
  --         -- { name = "bash-language-server" },
  --         -- { name = "obsidian" },
  --         { name = "ottor" },
  --       }),
  --       sorting = {
  --         priority_weight = 2,
  --         comparators = {
  --           -- require("copilot_cmp.comparators").prioritize,
  --           -- require("copilot_cmp.comparators").score,
  --           compare.offset,
  --           compare.exact,
  --           -- compare.scopes,
  --           compare.score,
  --           compare.recently_used,
  --           compare.locality,
  --           -- compare.kind,
  --           compare.sort_text,
  --           compare.length,
  --           compare.order,
  --           -- require("copilot_cmp.comparators").prioritize,
  --           -- require("copilot_cmp.comparators").score,
  --         },
  --       },
  --       formatting = {
  --         format = lspkind.cmp_format({
  --           mode = 'symbol', -- show only symbol annotations
  --           maxwidth = 50,   -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
  --           -- can also be a function to dynamically calculate max width such as
  --           -- maxwidth = function() return math.floor(0.45 * vim.o.columns) end,
  --           ellipsis_char = '...',    -- when popup menu exceed maxwidth, the truncated part would show ellipsis_char instead (must define maxwidth first)
  --           show_labelDetails = true, -- show labelDetails in menu. Disabled by default
  --
  --           -- The function below will be called before any actual modifications from lspkind
  --           -- so that you can provide more controls on popup customization. (See [#30](https://github.com/onsails/lspkind-nvim/pull/30))
  --           -- before = function(entry, vim_item)
  --           --   return vim_item
  --           -- end
  --           before = require("tailwind-tools.cmp").lspkind_format
  --         })
  --       },
  --     })
  --
  --     -- Set configuration for specific filetype.
  --     cmp.setup.filetype("gitcommit", {
  --       sources = cmp.config.sources({
  --         { name = "cmp_git" }, -- You can specify the `cmp_git` source if you were installed it.
  --       }, {
  --         { name = "buffer" },
  --       }),
  --     })
  --
  --     -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
  --     cmp.setup.cmdline({ "/", "?" }, {
  --       mapping = cmp.mapping.preset.cmdline(),
  --       sources = {
  --         { name = "buffer" },
  --       },
  --     })
  --
  --     -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
  --     cmp.setup.cmdline(":", {
  --       mapping = cmp.mapping.preset.cmdline(),
  --       sources = cmp.config.sources({
  --         { name = "path" },
  --       }, {
  --         { name = "cmdline" },
  --       }),
  --     })
  --   end,
  -- },
  -- 'saadparwaiz1/cmp_luasnip',
  -- "hrsh7th/cmp-buffer",     -- nvim-cmp source for buffer words
  -- "hrsh7th/cmp-nvim-lsp",
  -- "andersevenrud/cmp-tmux", -- tmux completion source for nvim-cmp
  -- "hrsh7th/cmp-path",       -- nvim-cmp source for filesystem paths
  -- "hrsh7th/cmp-cmdline",    -- use to command/search complete
  -- "octaltree/cmp-look",
  -- "lukas-reineke/cmp-rg",   -- ripgrep source for nvim-cmp
  {
    'saghen/blink.cmp',
    lazy = false, -- lazy loading handled internally
    -- optional: provides snippets for the snippet source
    dependencies = 'rafamadriz/friendly-snippets',

    -- use a release tag to download pre-built binaries
    -- v0.8.1 会闪退
    version = 'v0.8.0',
    -- OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
    -- build = 'cargo build --release',
    -- If you use nix, you can build from source using latest nightly rust with:
    -- build = 'nix run .#build-plugin',

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      -- 'default' for mappings similar to built-in completion
      -- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
      -- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
      -- see the "default configuration" section below for full documentation on how to define
      -- your own keymap.
      keymap = {
        preset = 'default',
        ["<S-Tab>"] = { "select_prev", "fallback" },
        ["<Tab>"] = { "select_next", "fallback" },
        ["<UP>"] = { "select_prev", "fallback" },
        ["<DOWN>"] = { "select_next", "fallback" },
        ['<CR>'] = {
          function(cmp)
            if cmp.snippet_active() then
              return cmp.accept()
            else
              return cmp.select_and_accept()
            end
          end,
          'snippet_forward',
          'fallback'
        },
        cmdline = {
          preset = 'enter',
          ["<S-Tab>"] = { "select_prev", "fallback" },
          ["<Tab>"] = { "select_next", "fallback" },
          ["<UP>"] = { "select_prev", "fallback" },
          ["<DOWN>"] = { "select_next", "fallback" },
        }
      },

      appearance = {
        -- Sets the fallback highlight groups to nvim-cmp's highlight groups
        -- Useful for when your theme doesn't support blink.cmp
        -- will be removed in a future release
        use_nvim_cmp_as_default = true,
        -- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- Adjusts spacing to ensure icons are aligned
        nerd_font_variant = 'mono'
      },

      completion = {
        -- 'prefix' will fuzzy match on the text before the cursor
        -- 'full' will fuzzy match on the text before *and* after the cursor
        -- example: 'foo_|_bar' will match 'foo_' for 'prefix' and 'foo__bar' for 'full'
        keyword = { range = 'full' },

        -- Disable auto brackets
        -- NOTE: some LSPs may add auto brackets themselves anyway
        accept = { auto_brackets = { enabled = false }, },

        -- Insert completion item on selection, don't select by default
        list = { selection = 'auto_insert' },
        -- or set per mode
        -- list = { selection = function(ctx) return ctx.mode == 'cmdline' and 'auto_insert' or 'preselect' end },

        -- Show documentation when selecting a completion item
        documentation = { auto_show = true, auto_show_delay_ms = 500 },

        -- Display a preview of the selected item on the current line
        ghost_text = { enabled = true },
      },


      -- default list of enabled providers defined so that you can extend it
      -- elsewhere in your config, without redefining it, via `opts_extend`
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
        -- optionally disable cmdline completions
        -- cmdline = {},
      },
      -- experimental signature help support
      -- signature = { enabled = true }
    },
    -- allows extending the providers array elsewhere in your config
    -- without having to redefine it
    opts_extend = { "sources.default" }
  },
}
