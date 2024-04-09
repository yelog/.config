return {
  "github/copilot.vim",
  config = function()
    -- vim.keymap.set('i', '<C-J>', function()
    --     vim.fn['copilot#Accept']('<CR>')
    --   end, { desc = 'copilot accept', replace_keycodes = false })
      vim.keymap.set('i', '<right>', 'copilot#Accept("\\<CR>")', {
          expr = true,
          replace_keycodes = false
        })
    vim.g.copilot_no_tab_map = true
  end
}
