-- suan/vim-instant-markdown
vim.g.instant_markdown_slow = 0
vim.g.instant_markdown_autostart = 0
vim.g.instant_markdown_autoscroll = 1

-- tpope/vim-markdown
vim.g.markdown_syntax_conceal = 0
vim.g.markdown_fenced_languages = { 'html', 'python', 'bash=sh', 'json', 'java', 'js=javascript', 'sql', 'yaml', 'Dockerfile' }

-- tenxsoydev/vim-markdown-checkswitch
vim.g.md_checkswitch_style = 'cycle'
--> custom color
vim.cmd [[highlight checkbox cterm=bold gui=bold guifg=#b16286]]
vim.cmd [[match checkbox /\v\[ \]/]]
vim.cmd [[highlight checkbox_checked cterm=bold gui=bold guifg=#3ac569]]
vim.cmd [[2match checkbox_checked /\v\[x\]/]]
