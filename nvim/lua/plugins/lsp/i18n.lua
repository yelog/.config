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
    require('i18n').setup()

    vim.keymap.set("n", "<leader>fi", require("i18n.integration.fzf").show_i18n_keys_with_fzf,
      { desc = "Fuzzy search i18n key" })
    vim.keymap.set("n", "<D-S-n>", require("i18n.integration.fzf").show_i18n_keys_with_fzf,
      { desc = "Fuzzy search i18n key" })
    vim.keymap.set("n", "<D-S-M-n>", "<cmd>I18nNextLocale<cr>", { desc = "Switch default I18n language" })
  end
}
