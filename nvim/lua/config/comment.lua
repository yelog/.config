require('Comment').setup(
    {
        toggler = {
            line = '<leader>//',
            block = 'gbc',
        },
        opleader = {
            line = '<leader>/',
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
