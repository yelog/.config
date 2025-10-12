return {
  {
    'saghen/blink.cmp',
    lazy = false, -- lazy loading handled internally
    -- optional: provides snippets for the snippet source
    dependencies = {
      'onsails/lspkind.nvim',
      'nvim-mini/mini.icons',
      'Kaiser-Yang/blink-cmp-avante',
      { 'L3MON4D3/LuaSnip', version = 'v2.*' },
      'joelazar/blink-calc'
      -- 'Exafunction/codeium.nvim',
      -- 'windwp/nvim-autopairs'
    },

    -- use a release tag to download pre-built binaries
    -- v0.8.1 会闪退
    version = '1.*',
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
        -- ["<Tab>"] = {
        --   "snippet_forward",
        --   function() -- sidekick next edit suggestion
        --     return require("sidekick").nes_jump_or_apply()
        --   end,
        --   function() -- if you are using Neovim's native inline completions
        --     return vim.lsp.inline_completion.get()
        --   end,
        --   "fallback"
        -- },
        -- ["<S-Tab>"] = { "select_prev", "fallback" },
        ["<CR>"] = { "select_and_accept", "fallback" },
      },
      cmdline = {
        completion = {
          menu = {
            auto_show = true,
          },
        },
        keymap = {
          preset = 'default',
          ["<Tab>"] = { "select_and_accept", "fallback" },
          ["<S-Tab>"] = { "select_prev", "fallback" },
        }
      },

      -- appearance = {
      --   -- Sets the fallback highlight groups to nvim-cmp's highlight groups
      --   -- Useful for when your theme doesn't support blink.cmp
      --   -- will be removed in a future release
      --   use_nvim_cmp_as_default = true,
      --   -- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      --   -- Adjusts spacing to ensure icons are aligned
      --   nerd_font_variant = 'mono'
      -- },
      fuzzy = { implementation = "prefer_rust_with_warning" },
      completion = {
        -- 'prefix' will fuzzy match on the text before the cursor
        -- 'full' will fuzzy match on the text before *and* after the cursor
        -- example: 'foo_|_bar' will match 'foo_' for 'prefix' and 'foo__bar' for 'full'
        keyword = { range = 'full' },

        -- Disable auto brackets
        -- NOTE: some LSPs may add auto brackets themselves anyway
        accept = { auto_brackets = { enabled = false }, },

        -- Insert completion item on selection, don't select by default
        list = { selection = { preselect = true, auto_insert = false } },
        -- or set per mode
        -- list = { selection = function(ctx) return ctx.mode == 'cmdline' and 'auto_insert' or 'preselect' end },

        -- Show documentation when selecting a completion item
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 500,
          window = { border = 'single' },
        },

        -- Display a preview of the selected item on the current line
        ghost_text = { enabled = true },

        menu = {
          auto_show = true,   -- automatically show the menu when typing
          border = 'rounded', -- border style for the menu
          draw = {
            -- We don't need label_description now because label and label_description are already
            -- combined together in label by colorful-menu.nvim.
            columns = { { "kind_icon" }, { "label", gap = 1 } },
            components = {
              kind_icon = {
                text = function(ctx)
                  local kind_icon, _, _ = require('mini.icons').get('lsp', ctx.kind)
                  return kind_icon
                end,
                -- (optional) use highlights from mini.icons
                highlight = function(ctx)
                  local _, hl, _ = require('mini.icons').get('lsp', ctx.kind)
                  return hl
                end,
              },
              kind = {
                -- (optional) use highlights from mini.icons
                highlight = function(ctx)
                  local _, hl, _ = require('mini.icons').get('lsp', ctx.kind)
                  return hl
                end,
              }
            },
          },
        },
      },
      snippets = { preset = 'luasnip' },
      -- default list of enabled providers defined so that you can extend it
      -- elsewhere in your config, without redefining it, via `opts_extend`
      sources = {
        default = { 'i18n', 'snippets', 'avante', 'lsp', 'path', 'buffer', 'calc' },
        -- optionally disable cmdline completions
        -- cmdline = {},
        providers = {
          lsp = { fallbacks = {} },
          avante = {
            module = 'blink-cmp-avante',
            name = 'Avante',
            opts = {
              -- options for blink-cmp-avante
            }
          },
          i18n = {
            name = 'i18n',
            module = 'i18n.integration.blink_source',
            opts = {
            },
          },
          calc = {
            name = 'Calc',
            module = 'blink-calc',
          },
        }
      },
    },
  },
  -- {
  --   "hrsh7th/nvim-cmp",
  --   dependencies = {
  --     'hrsh7th/cmp-nvim-lsp',
  --     'hrsh7th/cmp-buffer',
  --     'hrsh7th/cmp-path',
  --     'hrsh7th/cmp-cmdline',
  --     'hrsh7th/cmp-vsnip', -- For vsnip users.
  --     -- 'hrsh7th/cmp-nvim-lua',
  --     -- 'saadparwaiz1/cmp_luasnip', -- For luasnip users.
  --     -- 'dcampos/cmp-snippy', -- For snippy users.
  --     -- 'honza/vim-snippets', -- Snippet collection
  --     -- 'SirVer/ultisnips', -- For ultisnips users.
  --     'hrsh7th/vim-vsnip', -- For vsnip users.
  --   },
  --   config = function()
  --     local cmp = require('cmp')
  --     cmp.register_source('i18n', require('i18n.integration.cmp_source').new())
  --
  --     cmp.setup({
  --       snippet = {
  --         -- REQUIRED - you must specify a snippet engine
  --         expand = function(args)
  --           vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
  --           -- require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
  --           -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
  --           -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
  --           -- vim.snippet.expand(args.body) -- For native neovim snippets (Neovim v0.10+)
  --
  --           -- For `mini.snippets` users:
  --           -- local insert = MiniSnippets.config.expand.insert or MiniSnippets.default_insert
  --           -- insert({ body = args.body }) -- Insert at cursor
  --           -- cmp.resubscribe({ "TextChangedI", "TextChangedP" })
  --           -- require("cmp.config").set_onetime({ sources = {} })
  --         end,
  --       },
  --       window = {
  --         -- completion = cmp.config.window.bordered(),
  --         -- documentation = cmp.config.window.bordered(),
  --       },
  --       mapping = cmp.mapping.preset.insert({
  --         ['<C-b>'] = cmp.mapping.scroll_docs(-4),
  --         ['<C-f>'] = cmp.mapping.scroll_docs(4),
  --         ['<C-Space>'] = cmp.mapping.complete(),
  --         ['<C-e>'] = cmp.mapping.abort(),
  --         ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
  --       }),
  --       sources = cmp.config.sources({
  --         { name = 'i18n' },
  --         { name = 'nvim_lsp' },
  --         { name = 'vsnip' }, -- For vsnip users.
  --         -- { name = 'luasnip' }, -- For luasnip users.
  --         -- { name = 'ultisnips' }, -- For ultisnips users.
  --         -- { name = 'snippy' }, -- For snippy users.
  --       }, {
  --         { name = 'buffer' },
  --       })
  --     })
  --   end
  -- }
}
