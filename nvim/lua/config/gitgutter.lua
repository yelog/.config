-- airblade/vim-gitgutter
vim.g.gitgutter_diff_base = "HEAD"
vim.g.gitgutter_sign_allow_clobber = 0
vim.g.gitgutter_map_keys = 0
vim.g.gitgutter_override_sign_column_highlight = 0
vim.g.gitgutter_preview_win_floating = 1
vim.g.gitgutter_sign_added = "▍"
vim.g.gitgutter_sign_modified = "▍"
vim.g.gitgutter_sign_removed = "▶"
vim.g.gitgutter_sign_removed_first_line = "▔"
vim.g.gitgutter_sign_modified_removed = "▒"
-- cmd[[highlight GitGutterAdd    guifg=#009900 ctermfg=2]]
-- cmd[[highlight GitGutterChange guifg=#0099FF ctermfg=3]]
-- cmd[[highlight GitGutterDelete guifg=#ff2222 ctermfg=1]]
vim.api.nvim_set_hl(0, "GitGutterAdd", { fg = "#009900", ctermfg = 2 })
vim.api.nvim_set_hl(0, "GitGutterChange", { fg = "#0099FF", ctermfg = 3 })
vim.api.nvim_set_hl(0, "GitGutterDelete", { fg = "#ff2222", ctermfg = 1 })

-- ybian/smartim
vim.g.smartim_default = "com.apple.keylayout.ABC"

-- airblade/vim-rooter
vim.g.rooter_patterns = { ".git/" }
