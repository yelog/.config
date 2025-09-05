return {
  'yelog/i18n.nvim',
  lazy = true,
  ft = { "vue", "typescript" },
  dependencies = {
    'ibhagwan/fzf-lua',
    'nvim-treesitter/nvim-treesitter'
  },
  dev = true,
  config = function()
    require('i18n').setup({
      -- langs = { "zh_CN", "en_US" },
      langs = { 'zh', 'en' },
      files = {
        'src/locales/{langs}.json',
        -- { files = "src/locales/lang/{langs}/{module}.ts",            prefix = "{module}." },
        -- { files = "src/views/{bu}/locales/lang/{langs}/{module}.ts", prefix = "{bu}.{module}." },
        -- { files = "packages/locales/src/langs/{langs}/{module}.json", prefix = "{module}." },
      }
    })

    vim.keymap.set("n", "<leader>fi", require("i18n.integration.fzf").show_i18n_keys_with_fzf, { desc = "Fuzzy search i18n key" })
    vim.keymap.set("n", "<D-S-n>", require("i18n.integration.fzf").show_i18n_keys_with_fzf, { desc = "Fuzzy search i18n key" })
    vim.keymap.set("n", "<D-S-M-n>", "<cmd>I18nNextLang<cr>", { desc = "Switch default I18n language" })
  end
}
