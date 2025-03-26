return {
  "neovim/nvim-lspconfig", -- Configurations for Nvim LSP
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
  "alvan/vim-closetag", -- when "<table|", type > , will be "<table>|</table>"
  {
    "windwp/nvim-ts-autotag",
    config = function()
      require("nvim-ts-autotag").setup()
    end,
  },
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
  -- {
  --   "pmizio/typescript-tools.nvim",
  --   dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
  --   opts = {},
  -- },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { 'saghen/blink.cmp' },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "marksman",
          "lua_ls",
          "jsonls",
          "ts_ls",
          "volar",
          -- "vuels",
          "html",
          "svelte",
          "eslint",
          "rust_analyzer",
          "swift_mesonls",
          "lemminx",
          "tailwindcss",
          "unocss",
          "dockerls",
        },
      })
      -- Mappings.
      -- See `:help vim.diagnostic.*` for documentation on any of the below functions
      local opts = { noremap = true, silent = true }
      vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
      vim.keymap.set("n", "<leader>lk", vim.diagnostic.goto_prev, opts)
      vim.keymap.set("n", "<leader>lj", vim.diagnostic.goto_next, opts)
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
        vim.keymap.set("n", "gD", vim.lsp.buf.implementation, bufopts)
        vim.keymap.set("n", "<M-p>", vim.lsp.buf.hover, bufopts)
        vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, bufopts)
        vim.keymap.set("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, bufopts)
        vim.keymap.set("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, bufopts)
        vim.keymap.set("n", "<leader>wl", function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, bufopts)
        vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, bufopts)
        -- vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
        vim.keymap.set("n", "<leader>rn", function()
          return ":IncRename " .. vim.fn.expand("<cword>")
        end, { expr = true })
        vim.keymap.set("n", "<leader>la", vim.lsp.buf.code_action, bufopts)
        -- vim.keymap.set("n", "gu", vim.lsp.buf.references, bufopts) --use telesscope instead
        -- vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format { async = true } end, bufopts)

        if client.server_capabilities.documentSymbolProvider then
          navic.attach(client, bufnr)
        end
      end

      local lspconfig = require("lspconfig")
      local lsp_flags = {
        -- This is the default in Nvim 0.7+
        debounce_text_changes = 150,
      }

      -- Set up lspconfig.
      -- local capabilities = require("cmp_nvim_lsp").default_capabilities()
      local capabilities = require('blink.cmp').get_lsp_capabilities()
      lspconfig["marksman"].setup({
        on_attach = on_attach,
        flags = lsp_flags,
        capabilities = capabilities,
      })
      -- lspconfig["tsserver"].setup({
      --   on_attach = on_attach,
      --   flags = lsp_flags,
      --   settings = {
      --     completions = {
      --       completeFunctionCalls = true,
      --     },
      --   },
      -- })
      lspconfig["jsonls"].setup({
        on_attach = on_attach,
        flags = lsp_flags,
        settings = {
          completions = {
            completeFunctionCalls = true,
          },
        },
      })
      lspconfig["eslint"].setup({
        filetyps = { "vue", "javascript", "typescript" },
        on_attach = on_attach,
        flags = lsp_flags,
      })
      -- vue2
      -- lspconfig["vuels"].setup({
      --   filetyps = { "vue" },
      --   cmd = { "vls" },
      --   on_attach = on_attach,
      --   flags = lsp_flags,
      --   root_dir = lspconfig.util.root_pattern("package.json", "vite.config.ts"),
      --   settings = {
      --     config = {
      --       css = {},
      --       emmet = {},
      --       html = {
      --         suggest = {},
      --       },
      --       javascript = {
      --         format = {},
      --       },
      --       stylusSupremacy = {},
      --       typescript = {
      --         format = {
      --           enable = true,
      --         },
      --       },
      --       vetur = {
      --         completion = {
      --           autoImport = true,
      --           tagCasing = "kebab",
      --           useScaffoldSnippets = true,
      --         },
      --         format = {
      --           defaultFormatter = {
      --             html = "none",
      --             js = "prettier",
      --             ts = "prettier",
      --           },
      --           -- defaultFormatterOptions = {},
      --           -- scriptInitialIndent = false,
      --           -- styleInitialIndent = false
      --         },
      --         useWorkspaceDependencies = false,
      --         validation = {
      --           script = true,
      --           style = true,
      --           template = true,
      --           templateProps = true,
      --           interpolation = true,
      --         },
      --         exprimental = {
      --           templateInterpolationService = true,
      --         },
      --       },
      --     },
      --   },
      -- })
      -- 目前只能支持 vue3,
      lspconfig["volar"].setup({
        filetyps = { "vue" },
        cmd = { 'vue-language-server', '--stdio' },
        on_attach = on_attach,
        flags = lsp_flags,
        root_dir = lspconfig.util.root_pattern("package.json"),
        settings = {
          config = {
            css = {},
            emmet = {},
            html = {
              suggest = {},
            },
            javascript = {
              format = {},
            },
            stylusSupremacy = {},
            typescript = {
              format = {
                enable = true,
              },
            },
            vetur = {
              completion = {
                autoImport = true,
                tagCasing = "kebab",
                useScaffoldSnippets = true,
              },
              format = {
                defaultFormatter = {
                  html = "none",
                  js = "prettier",
                  ts = "prettier",
                },
                -- defaultFormatterOptions = {},
                -- scriptInitialIndent = false,
                -- styleInitialIndent = false
              },
              useWorkspaceDependencies = false,
              validation = {
                script = true,
                style = true,
                template = true,
                templateProps = true,
                interpolation = true,
              },
              exprimental = {
                templateInterpolationService = true,
              },
            },
          },
        },
      })
      lspconfig["html"].setup({
        on_attach = on_attach,
        flags = lsp_flags,
      })
      lspconfig["svelte"].setup({
        on_attach = on_attach,
        flags = lsp_flags,
      })
      lspconfig["lemminx"].setup({
        on_attach = on_attach,
        flags = lsp_flags,
      })
      lspconfig["tailwindcss"].setup({
        on_attach = on_attach,
        filetyps = { "vue", "html" },
        flags = lsp_flags,
      })
      lspconfig["unocss"].setup({
        on_attach = on_attach,
        filetyps = { "vue", "html" },
        flags = lsp_flags,
      })
      lspconfig["dockerls"].setup({
        on_attach = on_attach,
        filetyps = { "dockerfile" },
        flags = lsp_flags,
      })
      -- lspconfig["bash-language-server"].setup({
      -- 	on_attach = on_attach,
      -- 	flags = lsp_flags,
      -- 	capabilities = capabilities,
      -- })
      -- lspconfig["pyright"].setup({
      --   on_attach = on_attach,
      --   flags = lsp_flags,
      -- })
      lspconfig["ts_ls"].setup({
        on_attach = on_attach,
        flags = lsp_flags,
        capabilities = capabilities,
        init_options = {
          plugins = { -- I think this was my breakthrough that made it work
            {
              name = "@vue/typescript-plugin",
              location = "/Users/yelog/Library/pnpm/global/5/node_modules/@vue/language-server",
              languages = { "vue" },
            },
          },
        },
        filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
      })
      lspconfig["rust_analyzer"].setup({
        on_attach = on_attach,
        flags = lsp_flags,
        -- Server-specific settings...
        settings = {
          ["rust-analyzer"] = {},
        },
      })
      lspconfig["swift_mesonls"].setup({
        on_attach = on_attach,
        flags = lsp_flags,
        -- Server-specific settings...
        settings = {
          ["swift_mesonls"] = {},
        },
      })
      -- example to setup sumneko and enable call snippets
      -- local runtime_path = vim.split(package.path, ";")
      -- table.insert(runtime_path, "lua/?.lua")
      -- table.insert(runtime_path, "lua/?/init.lua")

      local runtime_path = vim.split(package.path, ";")
      lspconfig["lua_ls"].setup({
        on_attach = on_attach,
        settings = {
          Lua = {
            runtime = {
              version = "LuaJIT",
              path = runtime_path,
            },
            diagnostics = {
              globals = { "vim" },
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
      -- vim.api.nvim_create_autocmd("FileType", {
      -- 	pattern = "sh",
      -- 	callback = function()
      -- 		vim.lsp.start({
      -- 			name = "bash-language-server",
      -- 			cmd = { "bash-language-server", "start" },
      -- 		})
      -- 	end,
      -- })
      -- require("typescript-tools").setup {
      --   on_attach = on_attach,
      --   settings = {
      --     -- spawn additional tsserver instance to calculate diagnostics on it
      --     separate_diagnostic_server = true,
      --     -- "change"|"insert_leave" determine when the client asks the server about diagnostic
      --     publish_diagnostic_on = "insert_leave",
      --     -- array of strings("fix_all"|"add_missing_imports"|"remove_unused")
      --     -- specify commands exposed as code_actions
      --     expose_as_code_action = {},
      --     -- string|nil - specify a custom path to `tsserver.js` file, if this is nil or file under path
      --     -- not exists then standard path resolution strategy is applied
      --     tsserver_path = nil,
      --     -- specify a list of plugins to load by tsserver, e.g., for support `styled-components`
      --     -- (see 💅 `styled-components` support section)
      --     tsserver_plugins = {},
      --     -- this value is passed to: https://nodejs.org/api/cli.html#--max-old-space-sizesize-in-megabytes
      --     -- memory limit in megabytes or "auto"(basically no limit)
      --     tsserver_max_memory = "auto",
      --     -- described below
      --     tsserver_format_options = {},
      --     tsserver_file_preferences = {},
      --     -- mirror of VSCode's `typescript.suggest.completeFunctionCalls`
      --     complete_function_calls = false,
      --   },
      -- }
    end,
  },
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    requires = {
      'williamboman/mason.nvim',
    },
    config = function()
      require('mason-tool-installer').setup({
        ensure_installed = {
          'stylua',
          'jq',
          'prettier',
          'tailwindcss',
          'unocss',
        },
      })
    end,
  },
  {
    "smjonas/inc-rename.nvim",
    config = function()
      require("inc_rename").setup()
    end,
  }
  -- {
  --   "nvimdev/lspsaga.nvim" -- 显示文件路径
  -- },
  -- {
  --   "nabekou29/js-i18n.nvim",
  --   dependencies = {
  --     "neovim/nvim-lspconfig",
  --     "nvim-treesitter/nvim-treesitter",
  --     "nvim-lua/plenary.nvim",
  --   },
  --   event = { "BufReadPre", "BufNewFile" },
  --   opts = {
  --     primary_language = {},                               -- The default language to display (initial setting for displaying virtual text, etc.)
  --     translation_source = { "**/{locales,messages}/*.ts" }, -- Pattern for translation resources
  --     key_separator = ".",                                 -- Key separator
  --     virt_text = {
  --       enabled = true,                                    -- Enable virtual text display
  --       format = ...,                                      -- Format function for virtual text
  --       conceal_key = false,                               -- Hide keys and display only translations
  --       fallback = false,                                  -- Fallback if the selected virtual text cannot be displayed
  --       max_length = 0,                                    -- Maximum length of virtual text. 0 means unlimited.
  --       max_width = 0,                                     -- Maximum width of virtual text. 0 means unlimited. (`max_length` takes precedence.)
  --     },
  --     diagnostic = {
  --       enabled = true,                      -- Enable the display of diagnostic information
  --       severity = vim.diagnostic.severity.WARN, -- Severity level of diagnostic information
  --     },
  --   }
  -- }
}
