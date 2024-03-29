-- color scheme: More4 https://brandcolors.net/
--> custom color
vim.cmd([[highlight checkbox cterm=bold gui=bold guifg=#706357]])
vim.fn.matchadd("checkbox", "\\v\\[ \\]")
vim.cmd([[highlight checkbox_checked cterm=bold gui=bold guifg=#009f4d]])
vim.fn.matchadd("checkbox_checked", "\\v\\[x\\]")

-->tag
vim.cmd([[highlight ye_tag guifg=#91be3e]])
vim.fn.matchadd("ye_tag", "\\v#[a-zA-Z-_\\u4e00-\\u9fa5]+")

-->important
vim.cmd([[highlight ye_import1 cterm=bold guifg=#efdf00]])
vim.fn.matchadd("ye_import1", "\\v( |^)@<=!(!)@!")
vim.cmd([[highlight ye_import2 cterm=bold guifg=#fe5000]])
vim.fn.matchadd("ye_import2", "\\v( |^)@<=!!(!)@!")
vim.cmd([[highlight ye_import3 cterm=bold guifg=#e4002b]])
vim.fn.matchadd("ye_import3", "\\v( |^)@<=!!!(!)@!")

-- vim.cmd([[highlight ye_link guifg=#5c92fa gui=underline cterm=underline]])
-- vim.fn.matchadd("ye_link", "\\v\\[\\[(\\S|\\s)*\\]\\]")

vim.cmd([[highlight ye_link guifg=#5c92fa gui=underline cterm=underline]])
vim.fn.matchadd("ye_link", "\\v(http|https):(\\S|\\s){-}( |$)")

-- 设置自定义高亮组，用于以问号结尾的语句
vim.cmd([[highlight QuestionSentence cterm=bold guifg=#e5c07b]])
-- 在进入或创建文件时应用规则
vim.cmd([[autocmd! BufEnter,BufNewFile * call matchadd('QuestionSentence', "\\v[a-zA-Z-_\\u4e00-\\u9fa5]+[?]")]])


-- Highlight today's date
-- Set highlight
vim.cmd([[
  hi Today ctermfg=Green cterm=standout gui=standout
]])
-- Get day of today
local today = os.date("%Y-%m-%d")
-- autocmd，Apply highlight when opening a Markdown file
vim.cmd(string.format([[
  augroup MarkdownHighlight
    autocmd!
    autocmd FileType markdown lua vim.cmd('match Today /\\V%s/')
  augroup END
]], today))


-- 设置 [!NOTE] 行的背景为淡蓝色
vim.cmd('highlight calloutNoteBg guibg=#ADD8E6 ctermbg=lightblue')


-- 匹配 [!NOTE] 行并应用颜色
-- vim.cmd([[syntax match calloutNoteBg / #\S\+/ containedin=ALL]])
-- vim.cmd([[syntax match QuestionSentence /title/ containedin=ALL]])
-- 设置 [!NOTE] 后面的文字为深蓝色
-- vim.cmd('highlight calloutNoteTitle guifg=#000080 ctermfg=darkblue')
-- vim.cmd([[autocmd! BufEnter,BufNewFile *.md call matchadd('calloutNoteTitle', "^>\s*\[!NOTE\]\s\+")]])
vim.cmd('highlight calloutNoteTitle guifg=#00CEE3 ctermfg=darkblue')
-- vim.cmd('highlight calloutNoteChar guifg=#F0CEE3 ctermfg=darkblue')
-- vim.cmd([[autocmd! BufEnter,BufNewFile *.md call matchadd('calloutNoteChar', ">\\s*\\[\\zs!NOTE", 10)]])
vim.cmd([[autocmd! BufEnter,BufNewFile *.md call matchadd('calloutNoteTitle', ">\\s*\\[!NOTE\\]\\s*\\zs.*$", 10)]])

