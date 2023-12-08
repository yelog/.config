return {
  {
    "L3MON4D3/LuaSnip",
    dependencies = { "rafamadriz/friendly-snippets" },
    config = function()
      -- require("luasnip").filetype_extend("ruby", { "rails" })
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local compare = require("cmp.config.compare")

      local check_backspace = function()
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0
            and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

      cmp.setup({
        snippet = {
          -- REQUIRED - you must specify a snippet engine
          expand = function(args)
            -- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
            luasnip.lsp_expand(args.body) -- For `luasnip` users.
            -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
            -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
          end,
        },
        window = {
          documentation = false,
          -- documentation = {
          --   border = "rounded",
          --   winhighlight = "NormalFloat:Pmenu,NormalFloat:Pmenu,CursorLine:PmenuSel,Search:None",
          -- },
          completion = {
            border = "rounded",
            winhighlight = "NormalFloat:Pmenu,NormalFloat:Pmenu,CursorLine:PmenuSel,Search:None",
          },
        },
        experimental = {
          ghost_text = true,
        },
        mapping = cmp.mapping.preset.insert({
          -- ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          -- ['<C-f>'] = cmp.mapping.scroll_docs(4),
          -- ['<Tab>'] = cmp.mapping.complete(),
          -- ['<C-e>'] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.jumpable(1) then
              luasnip.jump(1)
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            elseif luasnip.expandable() then
              luasnip.expand()
            elseif check_backspace() then
              -- cmp.complete()
              fallback()
            else
              fallback()
            end
          end, {
            "i",
            "s",
          }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, {
            "i",
            "s",
          }),
        }),
        sources = cmp.config.sources({
          {
            name = "nvim_lsp",
            filter = function(entry, ctx)
              local kind = require("cmp.types.lsp").CompletionItemKind[entry:get_kind()]
              if kind == "Snippet" then
                return true
              end

              if kind == "Text" then
                return true
              end
            end,
            group_index = 2,
          },
          { name = "luasnip", group_index = 2 }, -- For luasnip users
          {
            name = "buffer",
            group_index = 2,
          }, -- For buffer words
          -- { name = "tmux", group_index = 2 }, -- For tmux words
          -- { name = 'vsnip' }, -- For vsnip users
          { name = "path" }, -- For filesystem paths
          -- { name = "rg" }, -- For filesystem paths
          -- { name = 'ultisnips' }, -- For ultisnips users
          -- { name = 'snippy' }, -- For snippy users
          -- { name = "marksman" },
          -- { name = "tsserver" },
          -- { name = "bash-language-server" },
          { name = "obsidian" },
        }),
        sorting = {
          priority_weight = 2,
          comparators = {
            -- require("copilot_cmp.comparators").prioritize,
            -- require("copilot_cmp.comparators").score,
            compare.offset,
            compare.exact,
            -- compare.scopes,
            compare.score,
            compare.recently_used,
            compare.locality,
            -- compare.kind,
            compare.sort_text,
            compare.length,
            compare.order,
            -- require("copilot_cmp.comparators").prioritize,
            -- require("copilot_cmp.comparators").score,
          },
        },
        formatting = {
          fields = { "kind", "abbr", "menu" },
          format = function(entry, vim_item)
            -- Kind icons
            -- vim_item.kind = kind_icons[vim_item.kind]

            -- if entry.source.name == "cmp_tabnine" then
            --   vim_item.kind = icons.misc.Robot
            --   vim_item.kind_hl_group = "CmpItemKindTabnine"
            -- end
            -- if entry.source.name == "copilot" then
            --   vim_item.kind = icons.git.Octoface
            --   vim_item.kind_hl_group = "CmpItemKindCopilot"
            -- end
            --
            -- if entry.source.name == "emoji" then
            --   vim_item.kind = icons.misc.Smiley
            --   vim_item.kind_hl_group = "CmpItemKindEmoji"
            -- end
            --
            -- if entry.source.name == "crates" then
            --   vim_item.kind = icons.misc.Package
            --   vim_item.kind_hl_group = "CmpItemKindCrate"
            -- end
            --
            -- if entry.source.name == "lab.quick_data" then
            --   vim_item.kind = icons.misc.CircuitBoard
            --   vim_item.kind_hl_group = "CmpItemKindConstant"
            -- end
            --
            -- NOTE: order matters
            vim_item.menu = ({
              nvim_lsp = "",
              nvim_lua = "",
              luasnip = "",
              buffer = "",
              path = "",
              emoji = "",
            })[entry.source.name]
            return vim_item
          end,
        },
      })

      -- Set configuration for specific filetype.
      cmp.setup.filetype("gitcommit", {
        sources = cmp.config.sources({
          { name = "cmp_git" }, -- You can specify the `cmp_git` source if you were installed it.
        }, {
          { name = "buffer" },
        }),
      })

      -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
      })

      -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          { name = "cmdline" },
        }),
      })
    end,
  },
  'saadparwaiz1/cmp_luasnip',
  "hrsh7th/cmp-buffer", -- nvim-cmp source for buffer words
  "hrsh7th/cmp-nvim-lsp",
  "andersevenrud/cmp-tmux", -- tmux completion source for nvim-cmp
  "hrsh7th/cmp-path", -- nvim-cmp source for filesystem paths
  "hrsh7th/cmp-cmdline", -- use to command/search complete
  "octaltree/cmp-look",
  "lukas-reineke/cmp-rg", -- ripgrep source for nvim-cmp
}
