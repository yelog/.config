return {
  "LintaoAmons/scratch.nvim",
  event = 'VimEnter',
  tag = "v0.7.1",
  config = function()
    vim.keymap.set("n", "<leader>nn", "<cmd>Scratch<cr>")
    vim.keymap.set("n", "<leader>no", "<cmd>ScratchOpen<cr>")
  end
}
