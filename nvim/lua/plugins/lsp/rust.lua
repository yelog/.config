return {
  'mrcjkb/rustaceanvim',
  version = '^5', -- Recommended
  lazy = false,   -- This plugin is already lazy
  config = function()
    local bufnr = vim.api.nvim_get_current_buf()
    vim.keymap.set(
      "n",
      "<leader>a",
      function()
        vim.cmd.RustLsp('codeAction') -- supports rust-analyzer's grouping
        -- or vim.lsp.buf.codeAction() if you don't want grouping.
      end,
      { silent = true, buffer = bufnr }
    )
    vim.keymap.set(
      "n",
      "K", -- Override Neovim's built-in hover keymap with rustaceanvim's hover actions
      function()
        vim.cmd.RustLsp({ 'hover', 'action' })
      end,
      { silent = true, buffer = bufnr }
    )
  end
}
