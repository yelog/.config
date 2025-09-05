return {
  'yelog/i18n.nvim',
  lazy = true,
  ft = { "vue", "typescript", "java" },
  dependencies = {
    'ibhagwan/fzf-lua',
    'nvim-treesitter/nvim-treesitter'
  },
  dev = true,
  config = function()
    require('i18n').setup({
      -- locales = { "en_US", "zh_CN" },
      locales = { "zh", "en" },
      files = {
        'src/locales/{locales}.json',
        -- { files = 'src/locales/lang/{locales}/{module}.ts', prefix = "{module}." },
        -- 'moss-service-mes-kitting/moss-service-mes-kitting-server/src/main/resources/static/i18n/messages_{locales}.properties',
        -- 'moss-auth/src/main/resources/static/i18n/messages_{locales}.properties',
        -- { files = "src/views/{bu}/locales/lang/{locales}/{module}.ts", prefix = "{bu}.{module}." },
        -- { files = "packages/locales/src/locales/{locales}/{module}.json", prefix = "{module}." },
      },
      func_pattern = {
        "t%(['\"]([^'\"]+)['\"]",
        "%$t%(['\"]([^'\"]+)['\"]",
        "LangUtil.get%([\"]([^\"]+)[\"]",
      },
    })

    vim.keymap.set("n", "<leader>fi", require("i18n.integration.fzf").show_i18n_keys_with_fzf,
      { desc = "Fuzzy search i18n key" })
    vim.keymap.set("n", "<D-S-n>", require("i18n.integration.fzf").show_i18n_keys_with_fzf,
      { desc = "Fuzzy search i18n key" })
    vim.keymap.set("n", "<D-S-M-n>", "<cmd>I18nNextLocale<cr>", { desc = "Switch default I18n language" })
  end
}
