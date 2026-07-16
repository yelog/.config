return {
  -- {
  --   "github/copilot.vim",
  --   config = function()
  --     -- vim.keymap.set('i', '<c-j>', function()
  --     --     vim.fn['copilot#Accept']('<CR>')
  --     --   end, { desc = 'copilot accept', replace_keycodes = false })
  --     vim.keymap.set('i', '<c-j>', 'copilot#Accept("\\<CR>")', {
  --       expr = true,
  --       replace_keycodes = false
  --     })
  --     vim.g.copilot_no_tab_map = true
  --   end
  -- },
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      -- set lenovo proxy
      require('copilot').setup({
        panel = {
          enabled = false,
          auto_refresh = true,
          keymap = {
            jump_prev = "[[",
            jump_next = "]]",
            accept = "<CR>",
            refresh = "gr",
            open = "<D-CR>"
          },
          layout = {
            position = "bottom", -- | top | left | right
            ratio = 0.4
          },
        },
        suggestion = {
          enabled = false,
        },
        filetypes = {
          yaml = true,
          markdown = true,
          help = true,
          gitcommit = true,
          gitrebase = true,
          hgcommit = true,
          svn = false,
          cvs = true,
          ["."] = true,
        },
        copilot_node_command = 'node', -- Node.js version must be > 18.x
        server_opts_overrides = {},
        nes = {
          enabled = false,
          keymap = {
            accept_and_goto = "<leader>ii",
            accept = false,
            dismiss = "<Esc>",
          },
        },
      })
    end,
  }
}
