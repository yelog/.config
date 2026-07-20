return {
  "nickkadutskyi/jb.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    require("jb").setup({
      transparent = false,
    })

    local group = vim.api.nvim_create_augroup("JBTheme", { clear = true })
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = group,
      pattern = "jb",
      callback = function()
        require("custom.dap_style").apply_jb_highlights()

        local codelens = vim.api.nvim_get_hl(0, { name = "LspCodeLens", link = false })
        codelens.fg = "#727782"
        vim.api.nvim_set_hl(0, "LspCodeLens", codelens)
      end,
    })
  end,
}
