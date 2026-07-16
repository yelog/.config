return {
  {
    "mfussenegger/nvim-jdtls",
    event = { "BufReadPre *.java", "BufNewFile *.java" },
    dependencies = {
      "mfussenegger/nvim-dap",
      {
        "JavaHello/spring-boot.nvim",
        dependencies = {
          "neovim/nvim-lspconfig",
        },
        opts = {},
      },
    },
    config = function()
      local jdtls = require("jdtls")
      local navic = require("nvim-navic")

      local function get_jdtls_cmd(workspace_dir)
        local mason_path = vim.fn.stdpath("data") .. "/mason"
        local jdtls_path = mason_path .. "/packages/jdtls"

        return {
          jdtls_path .. "/bin/jdtls",
          "--jvm-arg=-javaagent:" .. jdtls_path .. "/lombok.jar",
          "--jvm-arg=-Xmx4G",
          "-data",
          workspace_dir,
        }
      end

      local function find_root(bufnr)
        return vim.fs.root(bufnr, {
          "mvnw",
          "gradlew",
          "settings.gradle",
          "settings.gradle.kts",
          ".git",
        }) or vim.fs.root(bufnr, {
          "pom.xml",
          "build.gradle",
          "build.gradle.kts",
          "build.xml",
        })
      end

      local function on_attach(client, bufnr)
        local bufopts = { noremap = true, silent = true, buffer = bufnr }

        vim.keymap.set("n", "<leader>la", vim.lsp.buf.code_action, bufopts)
        vim.keymap.set("n", "<M-CR>", vim.lsp.buf.code_action, bufopts)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
        vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, bufopts)
        vim.keymap.set({ "n", "i" }, "<C-k>", function()
          if not require('i18n').show_popup() then
            vim.lsp.buf.signature_help()
          end
        end, { desc = "i18n popup or signature help", buffer = bufnr })
        vim.keymap.set("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, bufopts)
        vim.keymap.set("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, bufopts)
        vim.keymap.set("n", "<leader>wl", function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, bufopts)

        vim.keymap.set("n", "<leader>jo", jdtls.organize_imports, { desc = "Java: Organize Imports", buffer = bufnr })
        vim.keymap.set("n", "<leader>jv", function() jdtls.extract_variable() end, { desc = "Java: Extract Variable", buffer = bufnr })
        vim.keymap.set("v", "<leader>jv", function() jdtls.extract_variable(true) end, { desc = "Java: Extract Variable", buffer = bufnr })
        vim.keymap.set("n", "<leader>jm", function() jdtls.extract_method() end, { desc = "Java: Extract Method", buffer = bufnr })
        vim.keymap.set("v", "<leader>jm", function() jdtls.extract_method(true) end, { desc = "Java: Extract Method", buffer = bufnr })

        -- 调试快捷键
        vim.keymap.set("n", "<leader>jd", function()
          require("jdtls.dap").setup_dap_main_class_configs({ verbose = true })
        end, { desc = "Java: Refresh Debug Config", buffer = bufnr })
        vim.keymap.set("n", "<leader>jt", function()
          vim.notify("Java Test debugging is disabled until java-test supports the jdtls ASM version", vim.log.levels.WARN)
        end, { desc = "Java: Test Nearest", buffer = bufnr })
        vim.keymap.set("n", "<leader>jT", function()
          vim.notify("Java Test debugging is disabled until java-test supports the jdtls ASM version", vim.log.levels.WARN)
        end, { desc = "Java: Test Class", buffer = bufnr })

        if client.server_capabilities.documentSymbolProvider then
          navic.attach(client, bufnr)
        end

        if client and client.supports_method("textDocument/foldingRange") then
          local win = vim.api.nvim_get_current_win()
          vim.wo[win].foldexpr = "v:lua.vim.lsp.foldexpr()"
        end

        local folding = require("custom.foldding")
        if folding and folding.schedule_import_fold then
          folding.schedule_import_fold(bufnr)
        end
      end

      local capabilities = require("blink.cmp").get_lsp_capabilities()
      local runtimes, launcher_home = require("custom.java_runtime").discover()

      local java_debug = require("custom.java_debug")
      local spring_bundles = require("spring_boot").java_extensions()
      local debug_bundles = java_debug.bundles()
      local toolchain_bundles = vim.list_extend(vim.list_extend({}, spring_bundles), debug_bundles)
      local toolchain_hash = java_debug.toolchain_fingerprint(nil, toolchain_bundles)

      local function get_workspace_dir(root_dir)
        local project_name = vim.fs.basename(root_dir)
        local project_hash = vim.fn.sha256(root_dir):sub(1, 12)
        return vim.fn.stdpath("cache") .. "/jdtls/workspace/" .. project_name .. "-" .. project_hash .. "-" .. toolchain_hash
      end

      local base_config = {
        capabilities = capabilities,
        on_attach = on_attach,
        cmd_env = launcher_home and { JAVA_HOME = launcher_home } or nil,
        settings = {
          java = {
            configuration = {
              updateBuildConfiguration = "interactive",
              runtimes = runtimes,
            },
            maven = {
              downloadSources = true,
            },
            autobuild = {
              enabled = true,
            },
            import = {
              gradle = {
                enabled = true,
                wrapper = {
                  enabled = true,
                },
              },
              maven = {
                enabled = true,
              },
              exclusions = {
                "**/node_modules/**",
                "**/.metadata/**",
                "**/archetype-resources/**",
                "**/META-INF/maven/**",
              },
            },
            eclipse = {
              downloadSources = true,
            },
            signatureHelp = {
              enabled = true,
            },
            contentProvider = {
              preferred = "fernflower",
            },
            completion = {
              favoriteStaticMembers = {
                "org.junit.jupiter.api.Assertions.*",
                "org.junit.Assert.*",
                "org.mockito.Mockito.*",
                "org.mockito.ArgumentMatchers.*",
                "org.mockito.BDDMockito.*",
                "org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*",
                "org.springframework.test.web.servlet.result.MockMvcResultMatchers.*",
                "org.assertj.core.api.Assertions.*",
                "java.util.Objects.requireNonNull",
                "java.util.Objects.requireNonNullElse",
                "org.apache.commons.lang3.StringUtils.*",
                "org.springframework.context.annotation.Bean",
                "org.springframework.web.bind.annotation.*",
                "org.springframework.stereotype.*",
                "java.util.stream.Collectors.*",
              },
              importOrder = {
                "java",
                "javax",
                "org",
                "com",
                "",
              },
              filteredTypes = {
                "com.sun.*",
                "io.micrometer.shaded.*",
              },
            },
            sources = {
              organizeImports = {
                starThreshold = 9999,
                staticStarThreshold = 9999,
              },
            },
            codeGeneration = {
              generateComments = true,
              hashCodeEquals = {
                useInstanceof = true,
                useJava7Objects = true,
              },
              useBlocks = true,
            },
            references = {
              includeDecompiledSources = true,
            },
            format = {
              enabled = true,
            },
          },
        },
        init_options = {
          bundles = toolchain_bundles,
          extendedClientCapabilities = jdtls.extendedClientCapabilities,
        },
      }

      local function start_or_attach(bufnr)
        if not launcher_home then
          vim.notify("jdtls: Java 21 or newer is required; set JAVA_HOME_21 or JAVA_HOME", vim.log.levels.ERROR)
          return
        end
        local root_dir = find_root(bufnr)
        if not root_dir then
          vim.notify("jdtls: no Maven, Gradle, Ant, or Git project root found", vim.log.levels.WARN)
          return
        end

        local workspace_dir = get_workspace_dir(root_dir)
        local config = vim.deepcopy(base_config)
        config.cmd = get_jdtls_cmd(workspace_dir)
        config.root_dir = root_dir
        jdtls.start_or_attach(config, { dap = { hotcodereplace = "auto" } }, { bufnr = bufnr })
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("nvim_jdtls", { clear = true }),
        pattern = "java",
        callback = function(args)
          start_or_attach(args.buf)
        end,
      })

      -- Command-line files can receive their FileType before lazy.nvim loads this plugin.
      if vim.bo.filetype == "java" then
        start_or_attach(vim.api.nvim_get_current_buf())
      end
    end,
  },
}
