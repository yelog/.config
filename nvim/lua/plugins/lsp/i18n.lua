return {
  'yelog/i18n.nvim',
  lazy = false,
  dependencies = {
    'ibhagwan/fzf-lua',
    -- 'nvim-telescope/telescope.nvim',
    'nvim-treesitter/nvim-treesitter'
  },
  dev = true,
  config = function()
    require('i18n').setup({
      usage = {
        -- Popup provider used when choosing between multiple usage locations
        -- Available values: 'vim_ui', 'telescope', 'fzf-lua', 'snacks'
        popup_type = 'fzf-lua',
      },
    })

    vim.keymap.set("n", "<leader>fi", require('i18n').show_i18n_keys_with_fzf,
      { desc = "Fuzzy search i18n key" })
    -- vim.keymap.set("n", "<D-S-n>", require("i18n").show_i18n_keys_with_telescope,
    --   { desc = "Search i18n key (Telescope)" })

    vim.keymap.set({ "n", 'i' }, "<D-S-n>", require('i18n').show_i18n_keys_with_fzf,
      { desc = "Fuzzy search i18n key" })
    vim.keymap.set("n", "<D-S-B>", "<cmd>I18nNextLocale<cr>", { desc = "Switch default I18n language" })
    vim.keymap.set("n", "<D-S-J>", "<cmd>I18nToggleOrigin<cr>", { desc = "Switch default I18n language" })
  end
}
