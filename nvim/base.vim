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
"set relativenumber                " 设置相对行号
set number                        " 插件 jeffkreeftmeijer/vim-numbertoggle 自动决定显示相对行号还是绝对行号
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
set foldmethod=manual             " 折叠代码
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
" set lazyredraw "same as above
set visualbell
set history=200 " Ex command history size

set hidden
set updatetime=100      " 响应快一些
set colorcolumn=100
set shortmess+=c        " 补全少一些没用的东西
set virtualedit=block
"set nowrapscan         " 不循环搜索

" 分屏
" map <leader>s <nop>
map <leader>sl :set splitright<CR>:vsplit<CR>
map <leader>sh :set nosplitright<CR>:vsplit<CR>
map <leader>sk :set nosplitbelow<CR>:split<CR>
map <leader>sj :set splitbelow<CR>:split<CR>
map <leader>sH <C-w>H
map <leader>sL <C-w>L
map <leader>sJ <C-w>J
map <leader>sK <C-w>K
map <leader>so <c-w>o
map <leader>sc <c-w>c
" 切换分屏焦点
noremap gl <C-w>l
noremap gh <C-w>h
noremap gj <C-w>j
noremap gk <C-w>k
" 分屏大小
noremap <up> :res -5<CR>
noremap <down> :res +5<CR>
noremap <left> :vertical resize-5<CR>
noremap <right> :vertical resize+5<CR>
map <c-w>V <c-w>s<cr>

" 标签页
map ti :tabe<CR>
"map th :-tabnext<CR>
map th gT
"map tl :+tabnext<CR>
map tl gt
map tmh :-tabmove<CR>
map tml :+tabmove<CR>

"nnoremap <c-p> gT
"nnoremap <c-n> gt
"inoremap <c-p> <esc>gT
"inoremap <c-n> <esc>gt

" 保存 退出 刷新配置文件
"map <LEADER>rc :e ~/.config/nvim/init.vim<CR>
" 'V
map <leader>S :w<CR>
noremap <C-s> :w<CR>
" map Q :q<CR>
" noremap <C-q> :qa<CR>
" map R :source ~/.config/nvim/init.vim<CR> :nohlsearch<CR>
"noremap J 5j
"noremap K 5k
"noremap n nzz
"noremap N Nzz
"noremap * *zz
"noremap # #zz
" Ctrl + U or E will move up/down the view port without moving the cursor
noremap <C-U> 5<C-y>
noremap <C-D> 5<C-e>
nnoremap <leader>i" viw<esc>a"<esc>hbi"<esc>lel
nnoremap <leader>i' viw<esc>a'<esc>hbi'<esc>lel
nnoremap <leader>i` viw<esc>a`<esc>hbi`<esc>lel
nnoremap <leader>i{ viw<esc>a}<esc>hbi{<esc>lel
nnoremap <leader>i} viw<esc>a}<esc>hbi{<esc>lel
nnoremap <leader>i[ viw<esc>a]<esc>hbi[<esc>lel
nnoremap <leader>i] viw<esc>a]<esc>hbi[<esc>lel
nnoremap <leader>i( viw<esc>a)<esc>hbi(<esc>lel
nnoremap <leader>i) viw<esc>a)<esc>hbi(<esc>lel
nnoremap <leader>i<space> viw<esc>a <esc>hbi <esc>lel
vnoremap <leader>i" xi""<esc>hp
vnoremap <leader>i' xi''<esc>hp
vnoremap <leader>i` xi``<esc>hp
vnoremap <leader>i{ xi{}<esc>hp
vnoremap <leader>i} xi{}<esc>hp
vnoremap <leader>i[ xi[]<esc>hp
vnoremap <leader>i] xi[]<esc>hp
vnoremap <leader>i) xi()<esc>hp
vnoremap <leader>i( xi()<esc>hp
vnoremap <leader>i<space> xi  <esc>hp

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
" map <LEADER>sc :set spell!<CR>
"noremap <C-x> ea<C-x>s

map ' `

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
" cnoremap <M-b> <S-Left>
" cnoremap <M-w> <S-Right>

" find and replace
noremap \s :%s/<c-r><c-w>/<c-r><c-w>/gI<left><left><left>

" set wrap
noremap <LEADER>sw :set wrap!<CR>

" 剪贴板
" 打通复制寄存器和粘贴板
" set clipboard=unnamedplus

" 普通模式下 Y 复制当前匿名寄存器到 Clipboard
nnoremap Y :let @+=@"<CR>
" 选中模式下 Y 复制到 Clipboard
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
let g:python3_host_prog='/usr/local/bin/python3'

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

"map <leader>l :let @*=expand("%")<CR>

"source ~/.config/nvim/cursor.vim
" Specify a directory for plugins
 " - For Neovim: stdpath('data') . '/plugged'
 " - Avoid using standard Vim directory names like 'plugin'


" 超长自动换行
"augroup my_textwidth
  "au!
  "autocmd FileType text,markdown,tex setlocal textwidth=80
"augroup END

autocmd FileChangedShell * let v:fcs_choice = 'reload'
