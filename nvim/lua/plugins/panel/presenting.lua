return {
  "sotte/presenting.nvim",
  opts = {
    -- fill in your options here
    -- see :help Presenting.config
    width = 100,
    keymaps = {
      -- These are local mappings for the open slide buffer.
      -- Disable existing keymaps by setting them to `nil`.
      -- Add your own keymaps as you desire.
      ["n"] = function() Presenting.next() end,
      ["p"] = function() Presenting.prev() end,
      ["q"] = function() Presenting.quit() end,
      -- ["f"] = function() Presenting.first() end,
      -- ["l"] = function() Presenting.last() end,
      -- ["<CR>"] = function() Presenting.next() end,
      -- ["<BS>"] = function() Presenting.prev() end,
    },

  },
  cmd = { "Presenting" },
}
