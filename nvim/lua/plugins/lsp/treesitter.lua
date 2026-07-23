return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    dependencies = { 'nvim-treesitter/nvim-treesitter-textobjects' },
    config = function()
      vim.g.markdown_fenced_languages =
      { "html", "python", "bash=sh", "json", "java", "javascript", "js=javascript", "sql", "yaml", "xml", "Dockerfile",
        "Rust", "swift", "lua", "typescript", "ts=typescript", "vim", "toml" }
      local treesitter = require("nvim-treesitter")
      treesitter.setup()
      treesitter.install({
        "java", "javascript", "typescript", "vue", "lua", "bash", "json", "yaml", "markdown", "markdown_inline",
        "html", "css", "rust", "toml",
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "java", "javascript", "typescript", "vue", "lua", "sh", "json", "yaml", "markdown", "html", "css", "rust", "toml" },
        callback = function(args) pcall(vim.treesitter.start, args.buf) end,
      })

      require("nvim-treesitter-textobjects").setup({
        select = {
          lookahead = true,
          selection_modes = {
            ["@parameter.outer"] = "v",
            ["@function.outer"] = "V",
            ["@class.outer"] = "<c-v>",
          },
          include_surrounding_whitespace = true,
        },
      })

      local select_textobject = require("nvim-treesitter-textobjects.select").select_textobject
      vim.keymap.set({ "x", "o" }, "af", function() select_textobject("@function.outer", "textobjects") end)
      vim.keymap.set({ "x", "o" }, "if", function() select_textobject("@function.inner", "textobjects") end)
      vim.keymap.set({ "x", "o" }, "ac", function() select_textobject("@class.outer", "textobjects") end)
      vim.keymap.set({ "x", "o" }, "ic", function() select_textobject("@class.inner", "textobjects") end)
      vim.keymap.set({ "x", "o" }, "as", function() select_textobject("@local.scope", "locals") end)
    end,
  },
}
