return {
  "neovim/nvim-lspconfig", -- Configurations for Nvim LSP
  "alvan/vim-closetag", -- when "<table|", type > , will be "<table>|</table>"
  {
    "windwp/nvim-ts-autotag",
    config = function()
      require("nvim-ts-autotag").setup()
    end,
  },
  "L3MON4D3/LuaSnip",
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
      })
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "marksman",
          -- "sumneko_lua",
          -- "rust_analyzer",
        },
      })
      -- Mappings.
      -- See `:help vim.diagnostic.*` for documentation on any of the below functions
      local opts = { noremap = true, silent = true }
      vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
      vim.keymap.set("n", "<leader>lp", vim.diagnostic.goto_prev, opts)
      vim.keymap.set("n", "<leader>ln", vim.diagnostic.goto_next, opts)
      vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, opts)

      -- Use an on_attach function to only map the following keys
      -- after the language server attaches to the current buffer
      local on_attach = function(client, bufnr)
        -- Enable completion triggered by <c-x><c-o>
        vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

        -- Mappings.
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        local bufopts = { noremap = true, silent = true, buffer = bufnr }
        -- vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
        vim.keymap.set("n", "gD", vim.lsp.buf.implementation, bufopts)
        -- vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
        vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, bufopts)
        vim.keymap.set("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, bufopts)
        vim.keymap.set("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, bufopts)
        vim.keymap.set("n", "<leader>wl", function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, bufopts)
        vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, bufopts)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, bufopts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
        -- vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format { async = true } end, bufopts)
      end

      local lspconfig = require("lspconfig")
      local lsp_flags = {
        -- This is the default in Nvim 0.7+
        debounce_text_changes = 150,
      }

      -- Set up lspconfig.
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      lspconfig["marksman"].setup({
        on_attach = on_attach,
        flags = lsp_flags,
        capabilities = capabilities,
      })
      lspconfig["marksman"].manager.try_add_wrapper()
      -- lspconfig["pyright"].setup({
      --   on_attach = on_attach,
      --   flags = lsp_flags,
      -- })
      -- lspconfig["tsserver"].setup({
      --   on_attach = on_attach,
      --   flags = lsp_flags,
      -- })
      -- lspconfig["rust_analyzer"].setup({
      --   on_attach = on_attach,
      --   flags = lsp_flags,
      --   -- Server-specific settings...
      --   settings = {
      --     ["rust-analyzer"] = {},
      --   },
      -- })
      -- example to setup sumneko and enable call snippets
      -- local runtime_path = vim.split(package.path, ";")
      -- table.insert(runtime_path, "lua/?.lua")
      -- table.insert(runtime_path, "lua/?/init.lua")

      -- lspconfig.sumneko_lua.setup({
      --   on_attach = on_attach,
      --   settings = {
      --     Lua = {
      --       runtime = {
      --         version = "LuaJIT",
      --         path = runtime_path,
      --       },
      --       diagnostics = {
      --         globals = { "vim" },
      --       },
      --       workspace = {
      --         library = vim.api.nvim_get_runtime_file("", true),
      --         checkThirdParty = false, -- THIS IS THE IMPORTANT LINE TO ADD
      --       },
      --       telemetry = {
      --         enable = false,
      --       },
      --     },
      --   },
      -- })
    end,
  },
  {
    "onsails/lspkind.nvim",
    config = function()
      require("lspkind").init({
        -- DEPRECATED (use mode instead): enables text annotations
        --
        -- default: true
        -- with_text = true,

        -- defines how annotations are shown
        -- default: symbol
        -- options: 'text', 'text_symbol', 'symbol_text', 'symbol'
        mode = "symbol_text",

        -- default symbol map
        -- can be either 'default' (requires nerd-fonts font) or
        -- 'codicons' for codicon preset (requires vscode-codicons font)
        --
        -- default: 'default'
        preset = "codicons",

        -- override preset symbols
        --
        -- default: {}
        symbol_map = {
          Text = "",
          Method = "",
          Function = "",
          Constructor = "",
          Field = "ﰠ",
          Variable = "",
          Class = "ﴯ",
          Interface = "",
          Module = "",
          Property = "ﰠ",
          Unit = "塞",
          Value = "",
          Enum = "",
          Keyword = "",
          Snippet = "",
          Color = "",
          File = "",
          Reference = "",
          Folder = "",
          EnumMember = "",
          Constant = "",
          Struct = "פּ",
          Event = "",
          Operator = "",
          TypeParameter = "",
        },
      })
      local lspkind = require("lspkind")
      local cmp = require("cmp")

      cmp.setup({
        formatting = {
          format = lspkind.cmp_format({
            mode = "symbol", -- show only symbol annotations
            maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
            ellipsis_char = "...", -- when popup menu exceed maxwidth, the truncated part would show ellipsis_char instead (must define maxwidth first)

            -- The function below will be called before any actual modifications from lspkind
            -- so that you can provide more controls on popup customization. (See [#30](https://github.com/onsails/lspkind-nvim/pull/30))
            before = function(entry, vim_item)
              return vim_item
            end,
          }),
        },
      })
    end,
  },
}
