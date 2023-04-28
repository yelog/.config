-- color scheme: More4 https://brandcolors.net/
--> custom color
vim.cmd([[highlight checkbox cterm=bold gui=bold guifg=#706357]])
vim.fn.matchadd("checkbox", "\\v\\[ \\]")
vim.cmd([[highlight checkbox_checked cterm=bold gui=bold guifg=#009f4d]])
vim.fn.matchadd("checkbox_checked", "\\v\\[x\\]")

-->tag
-- vim.cmd([[highlight ye_tag guifg=#91be3e]])
-- vim.fn.matchadd("ye_tag", "\\v#[a-zA-Z-_\\u4e00-\\u9fa5]+")

-->important
vim.cmd([[highlight ye_import1 cterm=bold guifg=#efdf00]])
vim.fn.matchadd("ye_import1", "\\v( |^)@<=!(!)@!")
vim.cmd([[highlight ye_import2 cterm=bold guifg=#fe5000]])
vim.fn.matchadd("ye_import2", "\\v( |^)@<=!!(!)@!")
vim.cmd([[highlight ye_import3 cterm=bold guifg=#e4002b]])
vim.fn.matchadd("ye_import3", "\\v( |^)@<=!!!(!)@!")

-- vim.cmd([[highlight ye_link guifg=#5c92fa gui=underline cterm=underline]])
-- vim.fn.matchadd("ye_link", "\\v\\[\\[(\\S|\\s)*\\]\\]")

vim.cmd([[highlight MarkdownHashtag guifg=#91be3e]])
vim.cmd([[syntax match MarkdownHashtag /#\S\+/ containedin=ALL]])
vim.cmd([[autocmd! BufEnter,BufNewFile *.md call matchadd('MarkdownHashtag', "\\v#[a-zA-Z-_\\u4e00-\\u9fa5]+")]])



