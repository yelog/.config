return {
  "numToStr/Comment.nvim",
  config = function()
    require('Comment').setup(
      {
        toggler = {
          line = '<M-/>',
          block = 'gbc',
        },
        opleader = {
          line = '<M-/>',
          block = 'gb',
        },
        extra = {
          above = 'gcO',
          below = 'gco',
          eol = 'gcA',
        },
        mappings = {
          basic = true,
          extra = true,
        },
        pre_hook = nil,
        post_hook = nil,
      }
    )
  end,
}
