return {
  "yelog/i18n.nvim",
  lazy = false, -- lazy loading handled internally
  dependencies = {
    "ibhagwan/fzf-lua"
  },
  dev = true,
  config = function()
    require("i18n").setup({
      mode = 'static',
      static = {
        langs = { "zh_CN", "en_US" },
        -- langs = { "zh", "en" },
        files = {
          -- "src/locales/{langs}.json",
          { files = "src/locales/lang/{langs}/{module}.ts",            prefix = "{module}." },
          { files = "src/views/{bu}/locales/lang/{langs}/{module}.ts", prefix = "{bu}.{module}." },
          -- { files = "packages/locales/src/langs/{langs}/{module}.json", prefix = "{module}." },
          -- { files = "src/views/{module}/lang/{langs}.json", prefix = "{module}." }
        }
      }
    })

    vim.keymap.set("n", "<leader>fi", require("i18n.integration.fzf").show_i18n_keys_with_fzf, { desc = "模糊查找 i18n key" })
    vim.keymap.set("n", "<D-S-n>", require("i18n.integration.fzf").show_i18n_keys_with_fzf, { desc = "模糊查找 i18n key" })
    vim.keymap.set("n", "<D-S-M-n>", "<cmd>I18nNextLang<cr>", { desc = "切换 I18n 默认语言" })
  end
}
