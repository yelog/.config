return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'master',
    build = ':TSUpdate',
    dependencies = { 'nvim-treesitter/nvim-treesitter-textobjects' },
    config = function()
      vim.g.markdown_fenced_languages =
      { "html", "python", "bash=sh", "json", "java", "javascript", "js=javascript", "sql", "yaml", "xml", "Dockerfile",
        "Rust", "swift", "lua", "typescript", "ts=typescript", "vim", "toml" }
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "java",
          "javascript",
          "typescript",
          "bash",
          "c",
          "lua",
          "rust",
          "css",
          "yaml",
          "json",
          "markdown",
          "markdown_inline",
          "vue",
        },
        sync_install = false,
        auto_install = true,
        highlight = { enable = true },
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
              ["as"] = { query = "@local.scope", query_group = "locals", desc = "Select language scope" },
            },
            selection_modes = {
              ['@parameter.outer'] = 'v',
              ['@function.outer'] = 'V',
              ['@class.outer'] = '<c-v>',
            },
            include_surrounding_whitespace = true,
          },
        },
      })
    end,
  },
}
