let mapleader=' '
"nnoremap ; :
set fileencodings=utf-8,ucs-bom,gb18030,gbk,gb2312,cp936
set termencoding=utf-8
set encoding=utf-8
set guifont=Monaco:h11
set exrc
set secure
set nu                            " 显示行号
syntax on
set ruler                         " 打开状态标尺
set cursorline                    " 突出显示当前行
set ignorecase smartcase          " 搜索时忽略大小写，但在有一个或以上大写字母时仍保持对大小写敏感
set infercase                     " 补全时自动判断该使用大写还是小写
set hlsearch                      " 搜索时高亮显示被找到的文本
set smartindent                   " 开启新行时使用智能自动缩进
set incsearch                     " 输入搜索内容时就显示搜索结果
set autochdir                     " 自动切换当前目录为当前文件所在的目录
set cmdheight=1                   " 设定命令行的行数为 1
set laststatus=2                  " 显示状态栏 默认值为 1, 无法显示状态栏
set completeopt=longest,noinsert,menuone,noselect,preview
"set complete+=k                   " 启用字典补全
set relativenumber                " 设置相对行号
set wrap                          " 超出换行
set wildmenu                      " 自动补全 并且提示后选项
set showcmd                       " 显示当前命令
set nocompatible                  " 兼容旧 vi
filetype on                       " 识别不同格式文件
filetype indent on
filetype plugin on
filetype plugin indent on
set mouse=a                       " 支持鼠标
let &t_ut=''                      " 修复配色错误的问题
set noexpandtab
set expandtab
set tabstop=2
set shiftwidth=2
set softtabstop=2
set tw=0
set indentexpr=
set list                          " 回车、空格等不可见字符
set listchars=tab:\|\ ,trail:▫
set foldmethod=indent             " 折叠代码
set foldlevel=99
set viewoptions=cursor,folds,slash,unix
let &t_SI = "\<Esc>]50;CursorShape=1\x7"    " normal 和 insert 模式的光标样式设置
let &t_SR = "\<Esc>]50;CursorShape=2\x7"
let &t_EI = "\<Esc>]50;CursorShape=0\x7"
" 记录上次光标位置
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
set scrolloff=4
"set notimeout
set viewoptions=cursor,folds,slash,unix
set ttyfast "should make scrolling faster
set lazyredraw "same as above
set visualbell
set history=200 " Ex command history size

set hidden
set updatetime=100      " 响应快一些
set colorcolumn=100
set shortmess+=c        " 补全少一些没用的东西
set virtualedit=block
"set nowrapscan         " 不循环搜索

" 分屏
map s <nop>
"map sl :set splitright<CR>:vsplit<CR>
"map sh :set nosplitright<CR>:vsplit<CR>
"map sk :set nosplitbelow<CR>:split<CR>
"map sj :set splitbelow<CR>:split<CR>
"map sV <C-w>t<C-w>H
"map sH <C-w>t<C-w>K
"map so <c-w>o
"map sc <c-w>c
" Rotate screens
"noremap srh <C-w>b<C-w>K
"noremap srv <C-w>b<C-w>H
" 切换分屏焦点
"noremap gl <C-w>l
"noremap gh <C-w>h
"noremap gj <C-w>j
"noremap gk <C-w>k
" 分屏大小
map <up> :res -5<CR>
map <down> :res +5<CR>
map <left> :vertical resize-5<CR>
map <right> :vertical resize+5<CR>
map <c-w>V <c-w>s<cr>

" 标签页
map ti :tabe<CR>
"map th :-tabnext<CR>
map th gT
"map tl :+tabnext<CR>
map tl gt
map tmh :-tabmove<CR>
map tml :+tabmove<CR>

nnoremap <c-p> gT
nnoremap <c-n> gt
"inoremap <c-p> <esc>gT
"inoremap <c-n> <esc>gt

" 保存 退出 刷新配置文件
"map <LEADER>rc :e ~/.config/nvim/init.vim<CR>
" 'V
map S :w<CR>
noremap <C-s> :w<CR>
map Q :q<CR>
noremap <C-q> :qa<CR>
map R :source ~/.config/nvim/init.vim<CR>
"noremap J 5j
"noremap K 5k
"noremap n nzz
"noremap N Nzz
"noremap * *zz
"noremap # #zz
" Ctrl + U or E will move up/down the view port without moving the cursor
noremap <C-U> 5<C-y>
noremap <C-D> 5<C-e>
nnoremap <leader>" viw<esc>a"<esc>hbi"<esc>lel
nnoremap <leader>' viw<esc>a'<esc>hbi'<esc>lel
nnoremap <leader>` viw<esc>a`<esc>hbi`<esc>lel
nnoremap <leader>{ viw<esc>a}<esc>hbi{<esc>lel
nnoremap <leader>} viw<esc>a}<esc>hbi{<esc>lel
nnoremap <leader>[ viw<esc>a]<esc>hbi[<esc>lel
nnoremap <leader>] viw<esc>a]<esc>hbi[<esc>lel
nnoremap <leader>( viw<esc>a)<esc>hbi(<esc>lel
nnoremap <leader>) viw<esc>a)<esc>hbi(<esc>lel
vnoremap <leader>" xi""<esc>hp
vnoremap <leader>' xi''<esc>hp
vnoremap <leader>` xi``<esc>hp
vnoremap <leader>{ xi{}<esc>hp
vnoremap <leader>} xi{}<esc>hp
vnoremap <leader>[ xi[]<esc>hp
vnoremap <leader>] xi[]<esc>hp
vnoremap <leader>) xi()<esc>hp
vnoremap <leader>( xi()<esc>hp

" 0 toggle ^ or 0
noremap  <expr>0     col('.') == 1 ? '^': '0'

" highlight
noremap <LEADER><CR> :nohlsearch<CR>
" vim实用技巧推荐，原nnoremap<silent> <C-l> :<C-u>nohlsearch<CR><C-l>` 不知道后面 <c-l>`是干嘛的，故去掉了
nnoremap<silent> <C-l> :<C-u>nohlsearch<CR>
" Press space twice to jump to the next '<++>' and edit it
autocmd FileType markdown noremap <LEADER><LEADER> <Esc>/<++><CR>:nohlsearch<CR>c4l

" Opening a terminal window
"noremap <LEADER>/ :set splitright<CR>:vsplit<CR>:term<CR>

" search selected text in visual mode
vnoremap <silent> * :<C-U>
  \let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>
  \gvy/<C-R><C-R>=substitute(
  \escape(@", '/\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>
  \gV:call setreg('"', old_reg, old_regtype)<CR>
vnoremap <silent> # :<C-U>
  \let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>
  \gvy?<C-R><C-R>=substitute(
  \escape(@", '?\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>
  \gV:call setreg('"', old_reg, old_regtype)<CR>


" spelling check with <space>sc
map <LEADER>sc :set spell!<CR>
"noremap <C-x> ea<C-x>s

" Indentation
"nnoremap < <<
"nnoremap > >>
"vnoremap < <gv
"vnoremap > >gv

" Folding
"noremap <silent> <LEADER>o za

" ===
" === Insert Mode Cursor Movement
" ===
inoremap <C-a> <ESC>A
" ===
" === Command Mode Cursor Movement
" ===
cnoremap <C-a> <Home>
cnoremap <C-e> <End>
cnoremap <C-p> <Up>
"cnoremap <C-n> <Down>
"cnoremap <C-b> <Left>
"cnoremap <C-f> <Right>
cnoremap <M-b> <S-Left>
cnoremap <M-w> <S-Right>

" find and replace
noremap \s :%s//gc<left><left><left>

" set wrap
noremap <LEADER>sw :set wrap!<CR>

" 剪贴板
" 普通模式下复制到行尾
nnoremap Y y$
" 选中模式下
vnoremap Y "+y

"nnoremap <c-p> "0p
"vnoremap <c-p> "0p

vnoremap // y/\V<C-R>=escape(@",'/\')<CR><CR>

" input %% to insert buffer path int command mode
cnoremap <expr> %% getcmdtype( ) == ':' ? expand('%:h').'/' : '%%'

" ===
" === Markdown snippets
" ===
" Snippets
source ~/.config/nvim/md-snippets.vim
" auto spell
"autocmd BufRead,BufNewFile *.md setlocal spell

" 同时打开多个文件
"function! MultipleEdit(p_list)
  "for p in a:p_list
    "for c in glob(p, 0, 1)
      "execute 'edit ' . c
    "endfor
  "endfor
"endfunction
"command! -bar -bang -nargs=+ -complete=file Edit call MultipleEdit([<f-args>])

let g:python_host_prog='/usr/bin/python2'
let g:python3_host_prog='/usr/bin/python3'

" ===
" === Terminal Behaviors
" ===
let g:neoterm_autoscroll = 1
autocmd TermOpen term://* startinsert
"tnoremap <C-N> <C-\><C-N>
"tnoremap <C-O> <C-\><C-N><C-O>
let g:terminal_color_0  = '#000000'
let g:terminal_color_1  = '#FF5555'
let g:terminal_color_2  = '#50FA7B'
let g:terminal_color_3  = '#F1FA8C'
let g:terminal_color_4  = '#BD93F9'
let g:terminal_color_5  = '#FF79C6'
let g:terminal_color_6  = '#8BE9FD'
let g:terminal_color_7  = '#BFBFBF'
let g:terminal_color_8  = '#4D4D4D'
let g:terminal_color_9  = '#FF6E67'
let g:terminal_color_10 = '#5AF78E'
let g:terminal_color_11 = '#F4F99D'
let g:terminal_color_12 = '#CAA9FA'
let g:terminal_color_13 = '#FF92D0'
let g:terminal_color_14 = '#9AEDFE'

" set filetype
au BufNewFile,BufRead *.ejs set filetype=html

nnoremap & :&&<CR>
xnoremap & :&&<CR>

"source ~/.config/nvim/cursor.vim
" Specify a directory for plugins
 " - For Neovim: stdpath('data') . '/plugged'
 " - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.config/nvim/plugged')

" Make sure you use single quotes


" Auto Complete
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'wellle/tmux-complete.vim'

" File navigation
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'Yggdroot/LeaderF', { 'do': './install.sh' }
" ranger in neovim
"Plug 'kevinhwang91/rnvimr'
Plug 'airblade/vim-rooter'
"Plug 'pechorin/any-jump.vim'

" 首屏
Plug 'glepnir/dashboard-nvim'
"Plug 'liuchengxu/vim-clap'

" Undo Tree
Plug 'mbbill/undotree'


" Pretty Dress
Plug 'bpietravalle/vim-bolt'
"Plug 'blueshirts/darcula'
"Plug 'doums/darcula'
"Plug 'theniceboy/nvim-deus'
Plug 'ellisonleao/gruvbox.nvim'
"Plug 'ful1e5/onedark.nvim'
Plug 'folke/tokyonight.nvim', { 'branch': 'main' }
"Plug 'catppuccin/nvim', {'as': 'catppuccin', 'branch': 'dev-remaster'}
Plug 'ryanoasis/vim-devicons'
Plug 'joshdick/onedark.vim'
" Status line
Plug 'theniceboy/eleline.vim'
Plug 'ojroques/vim-scrollstatus'
"Plug 'glepnir/spaceline.vim'
"Plug 'vim-airline/vim-airline'

" General Highlighter
Plug 'RRethy/vim-hexokinase', { 'do': 'make hexokinase' }
Plug 'RRethy/vim-illuminate'

" highlight
" HTML, CSS, JavaScript, PHP, JSON, etc.
Plug 'elzr/vim-json'
Plug 'neoclide/jsonc.vim'
Plug 'gko/vim-coloresque', { 'for': ['vim-plug', 'php', 'html', 'javascript', 'css', 'less'] }
"Plug 'pangloss/vim-javascript', { 'for' :['javascript', 'vim-plug'] }
Plug 'yuezk/vim-js', { 'for': ['vim-plug', 'php', 'html', 'javascript', 'css', 'less'] }
"Plug 'posva/vim- vue'
Plug 'mattn/emmet-vim'

" Markdown
Plug 'suan/vim-instant-markdown', {'for': 'markdown'}
"Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install_sync() }, 'for' :['markdown', 'vim-plug'] }
Plug 'dhruvasagar/vim-table-mode', { 'on': 'TableModeToggle' }
Plug 'mzlogin/vim-markdown-toc', { 'for': ['gitignore', 'markdown', 'vim-plug'] }
Plug 'dkarter/bullets.vim'
Plug 'godlygeek/tabular' " type ;Tabularize /= to align the =
"Plug 'plasticboy/vim-markdown'
Plug 'tpope/vim-markdown'
" <leader>tt 由于不知道如何修改快捷键，暂时不用
Plug 'jkramer/vim-checkbox'
Plug 'tenxsoydev/vim-markdown-checkswitch'
"Plug 'gabrielelana/vim-markdown'
"Plug 'vim-pandoc/vim-pandoc-syntax'
Plug 'vimwiki/vimwiki'

" Bookmarks
Plug 'kshenoy/vim-signature'
" Taglist
Plug 'liuchengxu/vista.vim'
" see the " paste and @ recored
"Plug 'junegunn/vim-peekaboo'
" display available keybindings in popup
Plug 'liuchengxu/vim-which-key', { 'on': ['WhichKey', 'WhichKey!'] }
"Plug 'hecal3/vim-leader-guide'
"Plug 'spinks/vim-leader-guide'
"Plug 'folke/which-key.nvim'

" edit/show/move enhancement
"Plug 'terryma/vim-multiple-cursors'
Plug 'dstein64/vim-startuptime'
Plug 'tpope/vim-repeat'
Plug 'itchyny/vim-cursorword'
Plug 'tpope/vim-speeddating'
Plug 'alvan/vim-closetag'
"Plug 'junegunn/goyo.vim' " distraction free writing mode
Plug 'tpope/vim-surround' " type ysks' to wrap the word with '' or type cs'` to change 'word' to `word`
Plug 'jiangmiao/auto-pairs'
Plug 'gcmt/wildfire.vim' " in Visual mode, type i' to select all text in '', or type i) i] i} ip; in normal mode, type enter to select {[ and on.
Plug 'scrooloose/nerdcommenter' " in <space>cc to comment a line
"Plug 'tpope/vim-capslock'  " Ctrl+L (insert) to toggle capslock
Plug 'easymotion/vim-easymotion'
Plug 'haya14busa/incsearch.vim'
Plug 'haya14busa/incsearch-easymotion.vim'
Plug 'rhysd/clever-f.vim'

" Treesitter
"Plug 'nvim-treesitter/nvim-treesitter'
"Plug 'nvim-treesitter/playground'

" Git
"Plug 'theniceboy/vim-gitignore', { 'for': ['gitignore', 'vim-plug'] }
"Plug 'fszymanski/fzf-gitignore', { 'do': ':UpdateRemotePlugins' }
Plug 'theniceboy/fzf-gitignore', { 'do': ':UpdateRemotePlugins' }
"Plug 'mhinz/vim-signify'
Plug 'airblade/vim-gitgutter'
Plug 'cohama/agit.vim'
Plug 'tpope/vim-fugitive'

" Snippets
" Plug 'SirVer/ultisnips'
Plug 'theniceboy/vim-snippets'

" todo smart to switch input method
" need install im-select (mac-only)
" curl -Ls https://raw.githubusercontent.com/daipeihust/im-select/master/install_mac.sh | sh
Plug 'ybian/smartim'

" autosave
Plug '907th/vim-auto-save'

" Comrade
"Plug 'beeender/Comrade'
"Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins', 'for' : 'java' }

Plug 'brooth/far.vim'

" float term
Plug 'voldikss/vim-floaterm'

" github ai coding complete
Plug 'github/copilot.vim'

" database
"Plug 'tpope/vim-dadbod'
"Plug 'kristijanhusak/vim-dadbod-ui'

" gB open url in the default
" g<cr> search word under cursor using default search engine
" gG Google search word under cursor
" gW Wikipedia search word under cursor
Plug 'dhruvasagar/vim-open-url'

" lsp
"Plug 'williamboman/nvim-lsp-installer'
"Plug 'neovim/nvim-lspconfig'

" A mroe adventurous wildmenu
if has('nvim')
  function! UpdateRemotePlugins(...)
    " Needed to refresh runtime files
    let &rtp=&rtp
    UpdateRemotePlugins
  endfunction

  Plug 'gelguy/wilder.nvim', { 'do': function('UpdateRemotePlugins') }
else
  Plug 'gelguy/wilder.nvim'

  " To use Python remote plugin features in Vim, can be skipped
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc'
endif

call plug#end()



" ===
" === Dress up my vim
" ===
"set termguicolors " enable true colors support
"let $NVIM_TUI_ENABLE_TRUE_COLOR=1
"set background=dark
"let ayucolor="mirage"
"let g:oceanic_next_terminal_bold = 1
"let g:oceanic_next_terminal_italic = 1
"let g:one_allow_italics = 1

"color deus
"hi NonText ctermfg=gray guifg=grey10
" 透明背景
"hi Normal ctermfg=252 ctermbg=none
"color monokai

"colorscheme darcula

"set background=dark
"colorscheme onedark
"set termguicolors

"colorscheme snazzy
"let g:SnazzyTransparent = 1

colorscheme onedark

"let g:tokyonight_style = "night"
"let g:tokyonight_italic_functions = 1
"let g:tokyonight_colors = {
  "\ 'hint': 'orange',
  "\ 'error': '#ff0000'
  "\ }
"" Load the colorscheme
"colorscheme tokyonight

"set background=dark " or light if you want light mode
colorscheme gruvbox

" ===
" === catppuccin
" ===
"lua << EOF
"require('config')
"EOF
"colorscheme catppuccin

"" ===
"" === NERDTree
"" ===
"map ff :NERDTreeToggle<CR>
""let NERDTreeMapOpenExpl = ""
""let NERDTreeMapUpdir = ""
"let NERDTreeMapUpdirKeepOpen = ""
""let NERDTreeMapOpenSplit = ""
""let NERDTreeOpenVSplit = ""
"let NERDTreeMapActivateNode = "l"
"let NERDTreeMapOpenInTab = ""
"let NERDTreeMapPreview = ""
"let NERDTreeMapCloseDir = "h"
"let NERDTreeMapChangeRoot = "y"


"" ==
"" == NERDTree-git
"" ==
"let g:NERDTreeIndicatorMapCustom = {
"    \ "Modified"  : "✹",
"    \ "Staged"    : "✚",
"    \ "Untracked" : "✭",
"    \ "Renamed"   : "➜",
"    \ "Unmerged"  : "═",
"    \ "Deleted"   : "✖",
"    \ "Dirty"     : "✗",
"    \ "Clean"     : "✔︎",
"    \ "Unknown"   : "?"
"    \ }
" ===
" === Leaderf
" ===
let g:Lf_WindowPosition = 'popup'
"nnoremap <c-p> :Leaderf file<CR>
"nnoremap <leader>r :Leaderf mru<CR>
let g:Lf_PreviewInPopup = 1
let g:Lf_PreviewCode = 1
let g:Lf_ShowHidden = 1
let g:Lf_ShowDevIcons = 1
let g:Lf_UseVersionControlTool = 0
let g:Lf_IgnoreCurrentBufferName = 1
let g:Lf_WildIgnore = {
        \ 'dir': ['.git', 'vendor', 'node_modules'],
        \ 'file': ['__vim_project_root']
        \}
let g:Lf_UseMemoryCache = 0
let g:Lf_UseCache = 0

" ===
" === FZF
" ===
function! s:get_git_root()
  let root = split(system('git rev-parse --show-toplevel'), '\n')[0]
  return v:shell_error ? '.' : root
endfunction

set rtp+=/usr/local/bin/fzf
""set rtp+=/home/linuxbrew/.linuxbrew/opt/fzf
""set rtp+=/home/david/.linuxbrew/opt/fzf
"noremap <silent> <C-f> :Files<CR>
"map <expr> <C-f> fugitive#head() != '' ? ':GFiles --cached --others --exclude-standard<CR>' : ':Files .<CR>'
"noremap <silent> <C-f> :Rg<CR>
"noremap <silent> <C-h> :History<CR>
"noremap <C-t> :BTags<CR>
"noremap <silent> <C-l> :Lines<CR>
noremap <silent> <leader>f :Files<CR>
noremap <leader>; :History:<cr>
noremap <leader>F :Rg<cr>
noremap <leader>b :Buffers<CR>
noremap <leader>r :History<CR>

let g:fzf_preview_window = 'right:60%'
let g:fzf_commits_log_options = '--graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr"'

function! s:list_buffers()
  redir => list
  silent ls
  redir END
  return split(list, "\n")
endfunction

function! s:delete_buffers(lines)
  execute 'bwipeout' join(map(a:lines, {_, line -> split(line)[0]}))
endfunction

command! -bang -nargs=* GGrep
  \ call fzf#vim#grep(
  \   'git grep --line-number -- '.shellescape(<q-args>), 0,
  \   fzf#vim#with_preview({'dir': systemlist('git rev-parse --show-toplevel')[0]}), <bang>0)

"command! -bang -nargs=* Rg
  "\ call fzf#vim#grep(
  "\   'rg --column --line-number --no-heading --color=always --smart-case '.shellescape(<q-args>), 1,
  "\   <bang>0 ? fzf#vim#with_preview('up:60%')
  "\           : fzf#vim#with_preview('right:60%:hidden', '?'),
  "\   <bang>0)

"command! BD call fzf#run(fzf#wrap({
  "\ 'source': s:list_buffers(),
  "\ 'sink*': { lines -> s:delete_buffers(lines) },
  "\ 'options': '--multi --reverse --bind ctrl-a:select-all+accept'
"\ }))
"
"noremap <c-d> :BD<CR>

let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.8 } }

" ===
" === coc.nvim
" ===
let g:coc_global_extensions = [
    \ 'coc-actions',
  \ 'coc-css',
  \ 'coc-java',
  \ 'coc-diagnostic',
  \ 'coc-explorer',
  \ 'coc-gitignore',
  \ 'coc-html',
  \ 'coc-json',
  \ 'coc-lists',
  \ 'coc-prettier',
  \ 'coc-python',
  \ 'coc-snippets',
  \ 'coc-sourcekit',
  \ 'coc-syntax',
  \ 'coc-tasks',
  \ 'coc-todolist',
  \ 'coc-translator',
  \ 'coc-tslint-plugin',
  \ 'coc-tsserver',
  \ 'coc-vetur',
  \ 'coc-eslint',
  \ 'coc-vimlsp',
  \ 'coc-picgo',
  \ 'coc-yaml',
  \ 'coc-sh',
  \ 'coc-yank']

" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
"inoremap <silent><expr> <TAB>
      "\ pumvisible() ? "\<C-n>" :
      "\ <SID>check_back_space() ? "\<TAB>" :
      "\ coc#refresh()
"inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

"function! s:check_back_space() abort
  "let col = col('.') - 1
  "return !col || getline('.')[col - 1]  =~# '\s'
"endfunction

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

" Make <CR> auto-select the first completion item and notify coc.nvim to
" format on enter, <cr> could be remapped by other vim plugin
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation.
nmap <silent> gD <Plug>(coc-definition)
"nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gd <Plug>(coc-implementation)
"nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window.
nnoremap sd :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction

" Formatting selected code.
"xmap <leader>f  <Plug>(coc-format-selected)
"nmap <leader>f  ggVG<Plug>(coc-format-selected)

" Symbol renaming.
"nmap <leader>rn <Plug>(coc-rename)
nmap ts <Plug>(coc-translator-p)
vmap <silent> ts <Plug>(coc-translator-pv)

" Remap for do codeAction of selected region
"function! s:cocActionsOpenFromSelected(type) abort
"  execute 'CocCommand actions.open ' . a:type
"endfunction
"xmap <silent> <leader>a :<C-u>execute 'CocCommand actions.open ' . visualmode()<CR>
"nmap <silent> <leader>a :<C-u>set operatorfunc=<SID>cocActionsOpenFromSelected<CR>g@
nmap <Leader>e :CocCommand explorer<CR>
nmap <D-1> :CocCommand explorer<CR>
"nmap <Leader>er <Cmd>call CocAction('runCommand', 'explorer.doAction', 'closest', ['reveal:0'], [['relative', 0, 'file']])<CR>
autocmd BufEnter * if (winnr("$") == 1 && &filetype == 'coc-explorer') | q | endif

" Use preset argument to open it
nmap <space>ed <Cmd>CocCommand explorer --preset .vim<CR>
nmap <space>ef <Cmd>CocCommand explorer --preset floating<CR>
nmap <space>ec <Cmd>CocCommand explorer --preset cocConfig<CR>
nmap <space>eb <Cmd>CocCommand explorer --preset buffer<CR>

" List all presets
nmap <space>el <Cmd>CocList explPresets<CR>





nnoremap <c-c> :CocCommand<CR>
" coctodolist
nnoremap <leader>tn :CocCommand todolist.create<CR>
nnoremap <leader>tl :CocList todolist<CR>
nnoremap <leader>tu :CocCommand todolist.download<CR>:CocCommand todolist.upload<CR>

" ===
" === Taglist
" ===
map <silent> T :TagbarOpenAutoClose<CR>


" ===
" === vim-instant-markdown
" ===
let g:instant_markdown_slow = 0
let g:instant_markdown_autostart = 0
" let g:instant_markdown_open_to_the_world = 1
" let g:instant_markdown_allow_unsafe_content = 1
" let g:instant_markdown_allow_external_content = 0
" let g:instant_markdown_mathjax = 1
let g:instant_markdown_autoscroll = 1

" ===
" === Bullets.vim
" ===
" let g:bullets_set_mappings = 0
let g:bullets_enabled_file_types = [
  \ 'markdown',
  \ 'text',
  \ 'gitcommit',
  \ 'scratch'
  \]

" ===
" === vim-markdown-toc
" ===
"let g:vmt_auto_update_on_save = 0
"let g:vmt_dont_insert_fence = 1
let g:vmt_cycle_list_item_markers = 1
let g:vmt_fence_text = 'TOC'
let g:vmt_fence_closing_text = '/TOC'

" coc-snippets
"imap <C-h> <Plug>(coc-snippets-expand)
"vmap <C-l> <Plug>(coc-snippets-select)
"let g:coc_snippet_next = '<c-l>'
"let g:coc_snippet_prev = '<c-h>'
"imap <C-l> <Plug>(coc-snippets-expand-jump)
let g:snips_author = 'Chris Yang'


" ===
" === tpope/vim-markdown
" ===
let g:markdown_syntax_conceal = 0
let g:markdown_fenced_languages = ['html', 'python', 'bash=sh', 'json', 'java', 'js=javascript', 'sql']

" ===
" === vim-table-mode
" ===
map <LEADER>tm :TableModeToggle<CR>
map <leader>tf :TableModeRealign<cr>

" ===
" === tenxsoydev/vim-markdown-checkswitch
" ===
nnoremap <silent> <leader>mc :CheckSwitch<cr>
vnoremap <silent> <leader>mc :CheckSwitch<cr>gv
" Cycle between NO checkbox, empty, and ticked checkboxes 
" or toggle between empty and ticked checkboxes
let g:md_checkswitch_style = 'cycle' "'cycle' or 'toggle'


" Compile function
"noremap r :call CompileRunGcc()<CR>
"func! CompileRunGcc()
  "exec "w"
  "if &filetype == 'c'
    "exec "!g++ % -o %<"
    "exec "!time ./%<"
  "elseif &filetype == 'cpp'
    "set splitbelow
    "exec "!g++ -std=c++11 % -Wall -o %<"
    ":sp
    ":res -15
    ":term ./%<
  "elseif &filetype == 'java'
    "exec "!javac %"
    "exec "!time java %<"
  "elseif &filetype == 'sh'
    ":!time bash %
  "elseif &filetype == 'python'
    "set splitbelow
    ":sp
    ":term python3 %
  "elseif &filetype == 'html'
    "silent! exec "!".g:mkdp_browser." % &"
  "elseif &filetype == 'markdown'
    "exec "InstantMarkdownPreview"
  "elseif &filetype == 'tex'
    "silent! exec "VimtexStop"
    "silent! exec "VimtexCompile"
  "elseif &filetype == 'dart'
    "exec "CocCommand flutter.run -d ".g:flutter_default_device." ".g:flutter_run_args
    "silent! exec "CocCommand flutter.dev.openDevLog"
  "elseif &filetype == 'javascript'
    "set splitbelow
    ":sp
    ":term export DEBUG="INFO,ERROR,WARNING"; node --trace-warnings .
  "elseif &filetype == 'go'
    "set splitbelow
    ":sp
    ":term go run .
  "endif
"endfunc

" ===
" === Python-syntax
" ===
let g:python_highlight_all = 1
" let g:python_slow_sync = 0


" ===
" === Goyo
" ===
"map <LEADER>gy :Goyo<CR>


" ===
" === vim-signature
" === Bookmarks
" ===
let g:SignatureMap = {
        \ 'Leader'             :  "m",
        \ 'PlaceNextMark'      :  "m,",
        \ 'ToggleMarkAtLine'   :  "mm",
        \ 'PurgeMarksAtLine'   :  "dm-",
        \ 'DeleteMark'         :  "dm",
        \ 'PurgeMarks'         :  "dm/",
        \ 'PurgeMarkers'       :  "dm?",
        \ 'GotoNextLineAlpha'  :  "mn",
        \ 'GotoPrevLineAlpha'  :  "",
        \ 'GotoNextSpotAlpha'  :  "",
        \ 'GotoPrevSpotAlpha'  :  "",
        \ 'GotoNextLineByPos'  :  "",
        \ 'GotoPrevLineByPos'  :  "",
        \ 'GotoNextSpotByPos'  :  "mn",
        \ 'GotoPrevSpotByPos'  :  "mp",
        \ 'GotoNextMarker'     :  "",
        \ 'GotoPrevMarker'     :  "",
        \ 'GotoNextMarkerAny'  :  "",
        \ 'GotoPrevMarkerAny'  :  "",
        \ 'ListLocalMarks'     :  "m/",
        \ 'ListLocalMarkers'   :  "m?"
        \ }
map gm mn
map gM mp
map shm :help Signature<CR>
nnoremap 'A 'Azz
nnoremap 'S 'Szz
nnoremap 'D 'Dzz
nnoremap 'F 'Fzz

" ===
" === Undotree
" ===
noremap <leader>u :UndotreeToggle<CR>
let g:undotree_DiffAutoOpen = 1
let g:undotree_SetFocusWhenToggle = 1
let g:undotree_ShortIndicators = 1
let g:undotree_WindowLayout = 2
let g:undotree_DiffpanelHeight = 8
let g:undotree_SplitWidth = 24
function g:Undotree_CustomMap()
  nmap <buffer> u <plug>UndotreeNextState
  nmap <buffer> e <plug>UndotreePreviousState
  nmap <buffer> U 5<plug>UndotreeNextState
  nmap <buffer> E 5<plug>UndotreePreviousState
endfunc


" Open up lazygit
noremap \g :Git
noremap <leader>gg :tabe<CR>:-tabmove<CR>:term lazygit<CR>
" ==
" == airblade/vim-gitgutter
" ==
" let g:gitgutter_signs = 0
"let g:gitgutter_diff_relative_to = 'working_tree'
let g:gitgutter_diff_base = 'HEAD'
let g:gitgutter_sign_allow_clobber = 0
let g:gitgutter_map_keys = 0
let g:gitgutter_override_sign_column_highlight = 0
let g:gitgutter_preview_win_floating = 1
let g:gitgutter_sign_added = '▎'
let g:gitgutter_sign_modified = '░'
let g:gitgutter_sign_removed = '▶'
let g:gitgutter_sign_removed_first_line = '▔'
let g:gitgutter_sign_modified_removed = '▒'
" autocmd BufWritePost * GitGutter
nnoremap <leader>gf :GitGutterFold<CR>
nnoremap <leader>gp :GitGutterPreviewHunk<CR>
nnoremap <leader>gk :GitGutterPrevHunk<CR>
nnoremap <leader>gj :GitGutterNextHunk<CR>

" ===
" === nvim-treesitter
" ===
"lua <<EOF
"require'nvim-treesitter.configs'.setup {
"  ensure_installed = {"typescript", "dart", "java"},     -- one of "all", "language", or a list of languages
"  highlight = {
"    enable = true,              -- false will disable the whole extension
"    disable = { "c", "rust" },  -- list of language that will be disabled
"  },
"}
"EOF

"" ===
"" === any-jump
"" ===
"" Normal mode: Jump to definition under cursore
"nnoremap si :AnyJump<CR>
"" Visual mode: jump to selected text in visual mode
"xnoremap si :AnyJumpVisual<CR>
"" Normal mode: open previous opened file (after jump)
"nnoremap <leader>ab :AnyJumpBack<CR>
"" Normal mode: open last closed search window again
"nnoremap <leader>al :AnyJumpLastResults<CR>
"let g:any_jump_window_width_ratio  = 0.8
"let g:any_jump_window_height_ratio = 0.9


" ===
" === AsyncRun
" ===
"noremap gp :AsyncRun git push<CR>


" ===
" === AsyncTasks
" ===
let g:asyncrun_open = 6


" ===
" === rnvimr
" ===
"let g:rnvimr_enable_ex = 1
"let g:rnvimr_enable_picker = 1
"let g:rnvimr_draw_border = 0
"let g:rnvimr_hide_gitignore = 0
"" let g:rnvimr_bw_enable = 1
"highlight link RnvimrNormal CursorLine
""nnoremap <leader>e :RnvimrToggle<CR><C-\><C-n>:RnvimrResize 0<CR>
"let g:rnvimr_action = {
            "\ '<C-t>': 'NvimEdit tabedit',
            "\ '<C-x>': 'NvimEdit split',
            "\ '<C-v>': 'NvimEdit vsplit',
            "\ 'gw': 'JumpNvimCwd',
            "\ 'yw': 'EmitRangerCwd'
            "\ }
"let g:rnvimr_layout = { 'relative': 'editor',
            "\ 'width': &columns,
            "\ 'height': &lines,
            "\ 'col': 0,
            "\ 'row': 0,
            "\ 'style': 'minimal' }
"let g:rnvimr_presets = [{'width': 1.0, 'height': 1.0}]


" ===
" === smartim
" ===
let g:smartim_default='com.apple.keylayout.ABC'
" fix slow in mutiple_cursor mode
function! Multiple_cursors_before()
  let g:smartim_disable = 1
endfunction
function! Multiple_cursors_after()
  unlet g:smartim_disable
endfunction

" ===
" === vim-easymotion
" ===
let g:EasyMotion_do_mapping = 0
let g:EasyMotion_do_shade = 0
let g:EasyMotion_smartcase = 1
let g:EasyMotion_startofline = 0 " keep cursor column when JK motion
map <leader> <Plug>(easymotion-prefix)
map <leader>j <Plug>(easymotion-j)
map <leader>k <Plug>(easymotion-k)
map <leader>l <Plug>(easymotion-lineforward)
map <leader>h <Plug>(easymotion-linebackward)
"map <leader>f <Plug>(easymotion-sn)
map <leader>w <Plug>(easymotion-bd-w)
"map n <Plug>(easymotion-next)
"map N <Plug>(easymotion-prev)
""map / <Plug>(easymotion-sn)
"map / <Plug>(incsearch-easymotion-/)
"map ? <Plug>(incsearch-easymotion-?)
"map g/ <Plug>(incsearch-easymotion-stay)
"map  ,s <Plug>(easymotion-sn)
"omap ,s <Plug>(easymotion-tn)
" You can use other keymappings like <C-l> instead of <cr>if you want to
" use these mappings as default search and sometimes want to move cursor with
" EasyMotion.
"function! s:incsearch_config(...) abort
  "return incsearch#util#deepextend(deepcopy({
  "\   'modules': [incsearch#config#easymotion#module({'overwin': 1})],
  "\   'keymap': {
  "\     "\<CR>": '<Over>(easymotion)'
  "\   },
  "\   'is_expr': 0
  "\ }), get(a:, 1, {}))
"endfunction
"augroup incsearch-easymotion
  "autocmd!
  "autocmd User IncSearchEnter autocmd! incsearch-easymotion-impl
"augroup END
"augroup incsearch-easymotion-impl
  "autocmd!
"augroup END

"function! IncsearchEasyMotion() abort
  "autocmd incsearch-easymotion-impl User IncSearchExecute :silent! call EasyMotion#Search(0, 2, 0)
  "return "\<CR>"
"endfunction
"let g:incsearch_cli_key_mappings = {
"\   "\<Space>": {
"\       'key': 'IncsearchEasyMotion()',
"\       'noremap': 1,
"\       'expr': 1
"\   }
"\ }

"noremap <silent><expr> /  incsearch#go(<SID>incsearch_config())
"noremap <silent><expr> ?  incsearch#go(<SID>incsearch_config({'command': '?'}))
"noremap <silent><expr> g/ incsearch#go(<SID>incsearch_config({'is_stay': 1}))
"nmap ' <Plug>(easymotion-overwin-f2)
"map E <Plug>(easymotion-j)
"map U <Plug>(easymotion-k)
"nmap ' <Plug>(easymotion-overwin-f)
"map \; <Plug>(easymotion-prefix)
"nmap ' <Plug>(easymotion-overwin-f2)
"map 'l <Plug>(easymotion-bd-jk)
"nmap 'l <Plug>(easymotion-overwin-line)
"map  'w <Plug>(easymotion-bd-w)
"nmap 'w <Plug>(easymotion-overwin-w)


vnoremap <silent> ic :<C-U>call <SID>MdCodeBlockTextObj('i')<CR>
onoremap <silent> ic :<C-U>call <SID>MdCodeBlockTextObj('i')<CR>

vnoremap <silent> ac :<C-U>call <SID>MdCodeBlockTextObj('a')<CR>
onoremap <silent> ac :<C-U>call <SID>MdCodeBlockTextObj('a')<CR>

function! s:MdCodeBlockTextObj(type) abort
  " the parameter type specify whether it is inner text objects or around
  " text objects.

  " Move the cursor to the end of line in case that cursor is on the opening
  " of a code block. Actually, there are still issues if the cursor is on the
  " closing of a code block. In this case, the start row of code blocks would
  " be wrong. Unless we can match code blocks, it is not easy to fix this.
  normal! $
  let start_row = searchpos('\s*```', 'bnW')[0]
  let end_row = searchpos('\s*```', 'nW')[0]

  let buf_num = bufnr()
  " For inner code blocks, remove the start and end line containing backticks.
  if a:type ==# 'i'
    let start_row += 1
    let end_row -= 1
  endif
  " echo a:type start_row end_row

  call setpos("'<", [buf_num, start_row, 1, 0])
  call setpos("'>", [buf_num, end_row, 1, 0])
  execute 'normal! `<V`>'
endfunction

" ===
" === dashboard
" ===
let g:mapleader="\<Space>"
let g:dashboard_default_executive ='fzf'
"nmap <Leader>ss :<C-u>SessionSave<CR>
"nmap <Leader>sl :<C-u>SessionLoad<CR>
"nnoremap <silent> <Leader>fh :DashboardFindHistory<CR>
"nnoremap <silent> <Leader>ff :DashboardFindFile<CR>
"nnoremap <silent> <Leader>tc :DashboardChangeColorscheme<CR>
"nnoremap <silent> <Leader>fa :DashboardFindWord<CR>
"nnoremap <silent> <Leader>fb :DashboardJumpMark<CR>
"nnoremap <silent> <Leader>cn :DashboardNewFile<CR>

" ===
" === eleline.vim
" ===
let g:airline_powerline_fonts = 0

" ===
" === vim-illuminate
" ===
let g:Illuminate_delay = 750
hi illuminatedWord cterm=undercurl gui=undercurl

" ===
" === Vista.vim
" === taglist
" ===
noremap <LEADER>v :Vista!!<CR>
noremap <leader>o :silent! Vista finder coc<CR>
let g:vista_icon_indent = ["╰─▸ ", "├─▸ "]
let g:vista_default_executive = 'coc'
let g:vista_fzf_preview = ['right:50%']
let g:vista#renderer#enable_icon = 1
let g:vista#renderer#icons = {
\   "function": "\uf794",
\   "variable": "\uf71b",
\  }
" function! NearestMethodOrFunction() abort
"   return get(b:, 'vista_nearest_method_or_function', '')
" endfunction
" set statusline+=%{NearestMethodOrFunction()}
" autocmd VimEnter * call vista#RunForNearestMethodOrFunction()

" ===
" === vim-auto-save
" ===
noremap <LEADER>as :AutoSaveToggle<CR>
let g:auto_save = 0  " enable AutoSave on Vim startup
"let g:auto_save_silent = 1  " do not display the auto-save notification
"let g:auto_save = 0
"augroup ft_markdown
"  au!
"  au FileType markdown let b:auto_save = 1
"  au FileType java let b:auto_save = 1
"augroup END

" ===
" === vim-which-key
" ===
nnoremap <silent> <LEADER> :WhichKey '<Space>'<CR>
"nnoremap <silent> <localleader> :WhichKey  ','<CR>
" cp is for file configurations
" let use of which key pattern
" Define a separator
"nnoremap <silent> <space> :WhichKey ' '<cr>
"vnoremap <silent> <space> :WhichKeyVisual ' '<cr>
"let g:which_key_map = {}
"call which_key#register(' ', "g:which_key_map")
"nnoremap <silent> <leader> :WhichKey '<Space>'<CR>
" By default timeoutlen is 1000 ms
set timeoutlen=600

"lua << EOF
"  require("which-key").setup {
"    -- your configuration comes here
"    -- or leave it empty to use the default settings
"    -- refer to the configuration section below
"    key_labels = {
"    -- override the label used to display some keys. It doesn't effect WK in any other way.
"    -- For example:
"    ["<space>"] = "SPC",
"    -- ["<cr>"] = "RET",
"    -- ["<tab>"] = "TAB",
"    },
"  }
"EOF

"let mapleader = '\pace>'
"nnoremap <silent> <leader> :<c-u>LeaderGuide '<Space>'<CR>
"vnoremap <silent> <leader> :<c-u>LeaderGuideVisual '<Space>'<CR>


" ===
" === undotree
" ===
silent !mkdir -p ~/.config/nvim/tmp/backup
silent !mkdir -p ~/.config/nvim/tmp/undo
"silent !mkdir -p ~/.config/nvim/tmp/sessions
set backupdir=~/.config/nvim/tmp/backup,.
set directory=~/.config/nvim/tmp/backup,.
if has('persistent_undo')
  set undofile
  set undodir=~/.config/nvim/tmp/undo,.
endif


" ===
" === wildfire
" ===
let g:wildfire_objects = ["i'", 'i"', "i)", "i]", "i}", "ip", "it"]

" ===
" === comrade
" ===
"autocmd FileType java exec "CocDisable"
"" Use deoplete.
"let g:deoplete#enable_at_startup = 1


" ===
" === far.vim
" ===
nnoremap <silent> <c-s-f>  :Farf<cr>
vnoremap <silent> <c-s-f>  :Farf<cr>

" ===
" === voldikss/vim-floaterm
" ===
noremap <LEADER>/ :FloatermNew<cr>
" ===
" === rhysd/clever-f.vim
" ===
map ; <Plug>(clever-f-repeat-forward)
map , <Plug>(clever-f-repeat-back)
let g:clever_f_smart_case=1
" show prompt on the bottom
"let g:clever_f_show_prompt=1


" ===
" === vim-pandoc/vim-pandoc-syntax
" ===
"augroup pandoc_syntax
    "au! BufNewFile,BufFilePre,BufRead *.md set filetype=markdown.pandoc
"augroup END

" ===
" === gelguy/wilder.nvim
" ===

" ++once supported in Nvim 0.4+ and Vim 8.1+
"autocmd CmdlineEnter * ++once call s:wilder_init() | call s:wilder#main#start()

"function! s:wilder_init() abort
    call wilder#setup({
          \ 'modes': [':', '/', '?'],
          \ 'next_key': '<Tab>',
          \ 'previous_key': '<S-Tab>',
          \ 'accept_key': '<Down>',
          \ 'reject_key': '<Up>',
          \ })
    " Can also be passed to the 'highlights' option
    call wilder#set_option('renderer', wilder#popupmenu_renderer({
          \ 'highlighter': wilder#basic_highlighter(),
          \ 'highlights': {
          \   'accent': wilder#make_hl('WilderAccent', 'Pmenu', [{}, {}, {'foreground': '#f4468f'}]),
          \ },
          \ }))
    " fuzzy
    call wilder#set_option('pipeline', [
          \   wilder#debounce(10),
          \   wilder#branch(
          \     wilder#cmdline_pipeline({
          \       'fuzzy': 1,
          \       'set_pcre2_pattern': 1,
          \     }),
          \     wilder#python_search_pipeline({
          \       'pattern': 'fuzzy',
          \     }),
          \   ),
          \ ])
"endfunction

" ===
" === airblade/vim-rooter
" ===
let g:rooter_patterns = ['.git/']
nnoremap <silent> <leader>tr :RooterToggle<cr>

" ===
" === lsp
" ===
"lua <<EOF
"require("nvim-lsp-installer").setup({
    "automatic_installation = true, -- automatically detect which servers to install (based on which servers are set up via lspconfig)
    "ui = {
        "icons = {
            "server_installed = "✓",
            "server_pending = "➜",
            "server_uninstalled = "✗"
        "}
    "}
"})
"EOF
