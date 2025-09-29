local folding = require('custom.foldding')

return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      vim.diagnostic.config({
        virtual_lines = true, -- 在行尾显示诊断信息
        -- virtual_text = {
        --   spacing = 4, -- 行尾 diagnostic 与代码之间的间距
        --   severity = vim.diagnostic.severity.ERROR, -- 行内只显示 ERROR 级别
        --   source = "always", -- 显示 diagnostic 来源
        --   prefix = "●", -- 行尾前缀符号，可自定义
        -- },
        signs = true,             -- 是否在左侧显示符号
        underline = true,         -- 是否下划线标记
        update_in_insert = false, -- 插入模式下是否更新 diagnostic
        severity_sort = true,
      })
    end
  }, -- Configurations for Nvim LSP
  -- 'nvim-java/nvim-java',
  -- {
  --   "maan2003/lsp_lines.nvim", -- multi-line diagnostics
  --   config = function()
  --     -- show tips of diagnostic on the end of line
  --     vim.diagnostic.config({
  --       virtual_lines = false, -- 在行尾显示诊断信息
  --       -- virtual_text = {
  --       --   prefix = '>',       -- 图标或字符，可以用 "", "●", ">>" 等
  --       --   spacing = 4,
  --       --   severity = nil,     -- 只显示特定级别，如 vim.diagnostic.severity.ERROR
  --       --   source = "if_many", -- 显示 diagnostic 来源
  --       -- },
  --       signs = true, -- 左侧 gutter 的符号
  --       underline = true,
  --       update_in_insert = false,
  --       severity_sort = true,
  --     })
  --     vim.keymap.set(
  --       "",
  --       "<Leader>lc",
  --       require("lsp_lines").toggle,
  --       { desc = "Toggle lsp_lines" }
  --     )
  --   end
  -- },
  {
    "SmiteshP/nvim-navic",
    config = function()
      local navic = require("nvim-navic")
      navic.setup {
        icons = {
          File          = "󰈙 ",
          Module        = " ",
          Namespace     = "󰌗 ",
          Package       = " ",
          Class         = "󰌗 ",
          Method        = "󰆧 ",
          Property      = " ",
          Field         = " ",
          Constructor   = " ",
          Enum          = "󰕘",
          Interface     = "󰕘",
          Function      = "󰊕 ",
          Variable      = "󰆧 ",
          Constant      = "󰏿 ",
          String        = "󰀬 ",
          Number        = "󰎠 ",
          Boolean       = "◩ ",
          Array         = "󰅪 ",
          Object        = "󰅩 ",
          Key           = "󰌋 ",
          Null          = "󰟢 ",
          EnumMember    = " ",
          Struct        = "󰌗 ",
          Event         = " ",
          Operator      = "󰆕 ",
          TypeParameter = "󰊄 ",
        },
        lsp = {
          auto_attach = false,
          preference = nil,
        },
        highlight = false,
        separator = " > ",
        depth_limit = 0,
        depth_limit_indicator = "..",
        safe_output = true,
        lazy_update_context = false,
        click = false,
        format_text = function(text)
          return text
        end,
      }
    end
  },
  {
    "windwp/nvim-ts-autotag",
    config = function()
      require("nvim-ts-autotag").setup()
    end,
  },
  {
    "mason-org/mason.nvim",
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
    "mason-org/mason-lspconfig.nvim",
    dependencies = { 'saghen/blink.cmp' },
    config = function()
      require("mason-lspconfig").setup({
        -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md
        ensure_installed = {
          "marksman",
          "lua_ls",
          "jsonls",
          "vue_ls",
          "vtsls",
          "eslint",
          "rust_analyzer",
          "tailwindcss",
          "unocss",
          "dockerls",
          "vimls",
          "jdtls",
          "lemminx",
          -- "kotlin_lsp",
        },
      })
      -- Mappings.
      -- See `:help vim.diagnostic.*` for documentation on any of the below functions
      local opts = { noremap = true, silent = true }
      -- vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
      vim.keymap.set("n", "<leader>lk", function()
        vim.diagnostic.jump({ count = -1, float = true })
      end, opts)
      vim.keymap.set("n", "<leader>lj", function()
        vim.diagnostic.jump({ count = 1, float = true })
      end, opts)
      vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, opts)
      local navic = require("nvim-navic")

      -- Use an on_attach function to only map the following keys
      -- after the language server attaches to the current buffer
      on_attach = function(client, bufnr)
        -- Enable completion triggered by <c-x><c-o>
        -- vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

        -- Mappings.
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        local bufopts = { noremap = true, silent = true, buffer = bufnr }
        -- vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
        -- vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts) --use telescope instead
        -- vim.keymap.set("n", "gD", vim.lsp.buf.implementation, bufopts)
        vim.keymap.set("n", "<M-p>", vim.lsp.buf.hover, bufopts)
        -- vim.keymap.set({ "n", "i" }, "<C-k>", vim.lsp.buf.signature_help, bufopts)
        vim.keymap.set({ "n", "i" }, "<C-k>", function()
          if not require('i18n').show_popup() then
            vim.lsp.buf.signature_help()
          end
        end, { desc = "i18n popup or signature help" })

        vim.keymap.set("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, bufopts)
        vim.keymap.set("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, bufopts)
        vim.keymap.set("n", "<leader>wl", function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, bufopts)
        vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, bufopts)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
        -- vim.keymap.set("n", "<leader>rn", function()
        --   return ":IncRename " .. vim.fn.expand("<cword>")
        -- end, { expr = true })
        vim.keymap.set("n", "<leader>la", vim.lsp.buf.code_action, bufopts)
        vim.keymap.set("n", "<M-CR>", vim.lsp.buf.code_action, bufopts)
        -- vim.keymap.set("n", "gu", vim.lsp.buf.references, bufopts) --use telesscope instead
        -- vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format { async = true } end, bufopts)

        if client.server_capabilities.documentSymbolProvider then
          navic.attach(client, bufnr)
        end
        -- folder
        if client and client.supports_method 'textDocument/foldingRange' then
          local win = vim.api.nvim_get_current_win()
          vim.wo[win].foldexpr = 'v:lua.vim.lsp.foldexpr()'
        end

        if folding and folding.schedule_import_fold then
          folding.schedule_import_fold(bufnr)
        end
      end

      -- require('java').setup()
      -- local lspconfig = require("lspconfig")
      local lsp_flags = {
        -- This is the default in Nvim 0.7+
        debounce_text_changes = 150,
      }
      -- lspconfig.jdtls.setup({})

      -- Set up lspconfig.
      -- local capabilities = require("cmp_nvim_lsp").default_capabilities()
      local capabilities = require('blink.cmp').get_lsp_capabilities()
      vim.lsp.enable('marksman')
      vim.lsp.config('jsonls', {
        on_attach = on_attach,
        flags = lsp_flags,
        capabilities = capabilities,
        settings = {
          completions = {
            completeFunctionCalls = true,
          },
        }
      })

      -- local base_on_attach = vim.lsp.config.eslint.on_attach
      vim.lsp.enable('eslint')
      -- vim.lsp.config("eslint", {
      -- auto fix on save
      -- on_attach = function(client, bufnr)
      --   if not base_on_attach then return end
      --
      --   base_on_attach(client, bufnr)
      --   vim.api.nvim_create_autocmd("BufWritePre", {
      --     buffer = bufnr,
      --     command = "LspEslintFixAll",
      --   })
      -- end,
      -- })
      -- If you are using mason.nvim, you can get the ts_plugin_path like this
      -- For Mason v1,
      -- local mason_registry = require('mason-registry')
      -- local vue_language_server_path = mason_registry.get_package('vue-language-server'):get_install_path() .. '/node_modules/@vue/language-server'
      -- For Mason v2,
      -- local vue_language_server_path = vim.fn.expand '$MASON/packages' .. '/vue-language-server' .. '/node_modules/@vue/language-server'
      -- or even
      -- local vue_language_server_path = vim.fn.stdpath('data') .. "/mason/packages/vue-language-server/node_modules/@vue/language-server"
      local vue_language_server_path = vim.fn.expand '$MASON/packages' ..
          '/vue-language-server' .. '/node_modules/@vue/language-server'
      local vue_plugin = {
        name = '@vue/typescript-plugin',
        location = vue_language_server_path,
        languages = { 'vue' },
        configNamespace = 'typescript',
      }
      vim.lsp.config('vtsls', {
        settings = {
          vtsls = {
            tsserver = {
              globalPlugins = {
                vue_plugin,
              },
            },
          },
        },
        filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
      })
      vim.lsp.config('vue_ls', {
        -- add filetypes for typescript, javascript and vue
        filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
        on_attach = on_attach,
        capabilities = capabilities,
        init_options = {
          vue = {
            -- disable hybrid mode
            hybridMode = false,
          },
        },
      })
      vim.lsp.enable('tailwindcss')
      vim.lsp.enable('unocss')
      vim.lsp.enable('vimls')
      vim.lsp.enable('jdtls')
      vim.lsp.enable('lemminx')
      -- vim.lsp.enable('kotlin_lsp')
      vim.lsp.config('dockerls', {
        settings = {
          docker = {
            languageserver = {
              formatter = {
                ignoreMultilineInstructions = true,
              },
            },
          }
        }
      })
      vim.lsp.config('rust_analyzer', {
        settings = {
          ['rust-analyzer'] = {
            diagnostics = {
              enable = false,
            }
          }
        }
      })
      -- example to setup sumneko and enable call snippets
      -- local runtime_path = vim.split(package.path, ";")
      -- table.insert(runtime_path, "lua/?.lua")
      -- table.insert(runtime_path, "lua/?/init.lua")

      vim.lsp.config('lua_ls', {
        on_attach = on_attach,
        flags = lsp_flags,
        capabilities = capabilities,
        settings = {
          Lua = {
            runtime = {
              version = "LuaJIT",
              path = vim.split(package.path, ";"),
            },
            diagnostics = {
              globals = { 'vim' },
            },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false, -- THIS IS THE IMPORTANT LINE TO ADD
            },
            telemetry = {
              enable = false,
            },
          },
        },
      })
    end,
  },
  -- {
  --   "smjonas/inc-rename.nvim",
  --   config = function()
  --     require("inc_rename").setup()
  --   end,
  -- }
}
