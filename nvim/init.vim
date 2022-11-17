source ~/.config/nvim/base.vim

call plug#begin('~/.config/nvim/plugged')

" Make sure you use single quotes


" Auto Complete
" Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Style
" Plug 'bpietravalle/vim-bolt'
"Plug 'blueshirts/darcula'
"Plug 'doums/darcula'
"Plug 'theniceboy/nvim-deus'
" Plug 'ellisonleao/gruvbox.nvim'
" Plug 'ful1e5/onedark.nvim'
" Plug 'folke/tokyonight.nvim', { 'branch': 'main' }
" Plug 'ryanoasis/vim-devicons'
" Plug 'joshdick/onedark.vim'
" Status line
"Plug 'ojroques/vim-scrollstatus'
"Plug 'glepnir/spaceline.vim'
"Plug 'vim-airline/vim-airline'
" Plug 'nvim-lualine/lualine.nvim'
" If you want to have icons in your statusline choose one of these
" Plug 'akinsho/bufferline.nvim', { 'tag': 'v2.*' }

" show color by color code
" Plug 'RRethy/vim-hexokinase', { 'do': 'make hexokinase' }
" automatically highlighting other uses of the word under the cursor
" Plug 'RRethy/vim-illuminate'
" Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

" Markdown
" Plug 'suan/vim-instant-markdown', {'for': 'markdown'}
"Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install_sync() }, 'for' :['markdown', 'vim-plug'] }
" Plug 'dhruvasagar/vim-table-mode', { 'on': 'TableModeToggle' }
" Plug 'dkarter/bullets.vim'
" Plug 'tpope/vim-markdown'
" Plug 'tenxsoydev/vim-markdown-checkswitch'
"Plug 'vimwiki/vimwiki'

" Bookmarks
Plug 'kshenoy/vim-signature'
" Plug 'liuchengxu/vista.vim'
" see the " paste and @ recored
Plug 'junegunn/vim-peekaboo'
" Plug 'folke/which-key.nvim'

" edit/show/move enhancement
"Plug 'terryma/vim-multiple-cursors'
" Plug 'dstein64/vim-startuptime'
Plug 'tpope/vim-repeat'
Plug 'itchyny/vim-cursorword'
Plug 'tpope/vim-speeddating'
Plug 'alvan/vim-closetag'
"Plug 'junegunn/goyo.vim' " distraction free writing mode
Plug 'tpope/vim-surround' " type ysks' to wrap the word with '' or type cs'` to change 'word' to `word`
Plug 'jiangmiao/auto-pairs'
" Plug 'gcmt/wildfire.vim' " in Visual mode, type i' to select all text in '', or type i) i] i} ip; in normal mode, type enter to select {[ and on.
"Plug 'scrooloose/nerdcommenter' " in <space>cc to comment a line
" Plug 'numToStr/Comment.nvim'
" Plug 'phaazon/hop.nvim'


" Git
Plug 'airblade/vim-gitgutter'
Plug 'kdheepak/lazygit.nvim'

" Snippets
" Plug 'SirVer/ultisnips'
" Plug 'theniceboy/vim-snippets'

" todo smart to switch input method
" need install im-select (mac-only)
" curl -Ls https://raw.githubusercontent.com/daipeihust/im-select/master/install_mac.sh | sh
Plug 'ybian/smartim'

" autosave
Plug '907th/vim-auto-save'

" Find And Replace Vim plugin
Plug 'brooth/far.vim'

" float term
"Plug 'voldikss/vim-floaterm'
" Plug 'akinsho/toggleterm.nvim', {'tag' : '*'}

" github ai coding complete
"Plug 'github/copilot.vim'

" gB open url in the default
" g<cr> search word under cursor using default search engine
" gG Google search word under cursor
" gW Wikipedia search word under cursor
Plug 'dhruvasagar/vim-open-url'

" A mroe adventurous wildmenu
" if has('nvim')
"   function! UpdateRemotePlugins(...)
"     " Needed to refresh runtime files
"     let &rtp=&rtp
"     UpdateRemotePlugins
"   endfunction
"
"   Plug 'gelguy/wilder.nvim', { 'do': function('UpdateRemotePlugins') }
" else
"   Plug 'gelguy/wilder.nvim'
"
"   " To use Python remote plugin features in Vim, can be skipped
"   Plug 'roxma/nvim-yarp'
"   Plug 'roxma/vim-hug-neovim-rpc'
" endif

" 自动决定显示相对行号还是绝对行号
Plug 'jeffkreeftmeijer/vim-numbertoggle'

" sessoin manager
" Plug 'rmagatti/auto-session'
Plug 'airblade/vim-rooter'
"Plug 'rmagatti/session-lens'

" even better % 👊 navigate and highlight matching words 👊 modern matchit and matchparen
" Plug 'andymass/vim-matchup'

" Plug 'jose-elias-alvarez/null-ls.nvim'

call plug#end()



" ===
" === Dress up my vim
" ===
"hi Visual term=reverse cterm=reverse guibg=Grey
" define line highlight color
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

" colorscheme onedark

"let g:tokyonight_style = "night"
"let g:tokyonight_italic_functions = 1
"let g:tokyonight_colors = {
  "\ 'hint': 'orange',
  "\ 'error': '#ff0000'
  "\ }
"" Load the colorscheme
"colorscheme tokyonight

"set background=dark " or light if you want light mode
" colorscheme gruvbox



" " ===
" " === coc.nvim
" " ===
" let g:coc_global_extensions = [
"     \ 'coc-actions',
"   \ 'coc-css',
"   \ 'coc-java',
"   \ 'coc-diagnostic',
"   \ 'coc-explorer',
"   \ 'coc-gitignore',
"   \ 'coc-html',
"   \ 'coc-vue',
"   \ 'coc-json',
"   \ 'coc-lists',
"   \ 'coc-prettier',
"   \ 'coc-python',
"   \ 'coc-snippets',
"   \ 'coc-sourcekit',
"   \ 'coc-syntax',
"   \ 'coc-tasks',
"   \ 'coc-todolist',
"   \ 'coc-translator',
"   \ 'coc-tslint-plugin',
"   \ 'coc-tsserver',
"   \ 'coc-vetur',
"   \ 'coc-eslint',
"   \ 'coc-vimlsp',
"   \ 'coc-picgo',
"   \ 'coc-yaml',
"   \ 'coc-sh',
"   \ 'coc-db',
"   \ 'coc-sumneko-lua',
"   \ 'coc-yank']
"
" " Use tab for trigger completion with characters ahead and navigate.
" " NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" " other plugin before putting this into your config.
" "inoremap <silent><expr> <TAB>
"       "\ pumvisible() ? "\<C-n>" :
"       "\ <SID>check_back_space() ? "\<TAB>" :
"       "\ coc#refresh()
" "inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
"
" "function! s:check_back_space() abort
"   "let col = col('.') - 1
"   "return !col || getline('.')[col - 1]  =~# '\s'
" "endfunction
"
" " Use <c-space> to trigger completion.
" " inoremap <silent><expr> <c-space> coc#refresh()
"
" " Make <CR> auto-select the first completion item and notify coc.nvim to
" " format on enter, <cr> could be remapped by other vim plugin
" " inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
" "                               \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
"
" " Use `[g` and `]g` to navigate diagnostics
" " Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
" nmap <silent> [g <Plug>(coc-diagnostic-prev)
" nmap <silent> ]g <Plug>(coc-diagnostic-next)
"
" " GoTo code navigation.
" nmap <silent> gd <Plug>(coc-definition)
" "nmap <silent> gy <Plug>(coc-type-definition)
" nmap <silent> gD <Plug>(coc-implementation)
" "nmap <silent> gr <Plug>(coc-references)
"
" " Use K to show documentation in preview window.
" nnoremap sd :call <SID>show_documentation()<CR>
"
" function! s:show_documentation()
"   if (index(['vim','help'], &filetype) >= 0)
"     execute 'h '.expand('<cword>')
"   elseif (coc#rpc#ready())
"     call CocActionAsync('doHover')
"   else
"     execute '!' . &keywordprg . " " . expand('<cword>')
"   endif
" endfunction
"
" " Formatting selected code.
" xmap <leader>fm  <Plug>(coc-format-selected)
" "nmap <leader>f  ggVG<Plug>(coc-format-selected)
"
" " Symbol renaming.
" "nmap <leader>rn <Plug>(coc-rename)
" nmap ts <Plug>(coc-translator-p)
" vmap <silent> ts <Plug>(coc-translator-pv)
"
" " Remap for do codeAction of selected region
" "function! s:cocActionsOpenFromSelected(type) abort
" "  execute 'CocCommand actions.open ' . a:type
" "endfunction
" "xmap <silent> <leader>a :<C-u>execute 'CocCommand actions.open ' . visualmode()<CR>
" "nmap <silent> <leader>a :<C-u>set operatorfunc=<SID>cocActionsOpenFromSelected<CR>g@
" " nmap <Leader>e :CocCommand explorer<CR>
" " nmap <D-1> :CocCommand explorer<CR>
" "nmap <Leader>er <Cmd>call CocAction('runCommand', 'explorer.doAction', 'closest', ['reveal:0'], [['relative', 0, 'file']])<CR>
" autocmd BufEnter * if (winnr("$") == 1 && &filetype == 'coc-explorer') | q | endif
"
" " Use preset argument to open it
" nmap <space>ed <Cmd>CocCommand explorer --preset .vim<CR>
" nmap <space>ef <Cmd>CocCommand explorer --preset floating<CR>
" nmap <space>ec <Cmd>CocCommand explorer --preset cocConfig<CR>
" nmap <space>eb <Cmd>CocCommand explorer --preset buffer<CR>
"
" " List all presets
" nmap <space>el <Cmd>CocList explPresets<CR>
"
" "nnoremap <c-c> :CocCommand<CR>
" " coctodolist
" nnoremap <leader>tn :CocCommand todolist.create<CR>
" nnoremap <leader>tl :CocList todolist<CR>
" nnoremap <leader>tu :CocCommand todolist.download<CR>:CocCommand todolist.upload<CR>

" ===
" === vim-instant-markdown
" ===
" let g:instant_markdown_slow = 0
" let g:instant_markdown_autostart = 0
" let g:instant_markdown_open_to_the_world = 1
" let g:instant_markdown_allow_unsafe_content = 1
" let g:instant_markdown_allow_external_content = 0
" let g:instant_markdown_mathjax = 1
" let g:instant_markdown_autoscroll = 1

" ===
" === Bullets.vim
" ===
" let g:bullets_set_mappings = 0
" let g:bullets_enabled_file_types = [
"   \ 'markdown',
"   \ 'text',
"   \ 'gitcommit',
"   \ 'scratch'
"   \]

" ===
" === tpope/vim-markdown
" ===
" let g:markdown_syntax_conceal = 0
" let g:markdown_fenced_languages = ['html', 'python', 'bash=sh', 'json', 'java', 'js=javascript', 'sql', 'yaml', 'Dockerfile']

" ===
" === tenxsoydev/vim-markdown-checkswitch
" ===
" nnoremap <silent> <leader>mc :CheckSwitch<cr>
" vnoremap <silent> <leader>mc :CheckSwitch<cr>gv
" Cycle between NO checkbox, empty, and ticked checkboxes 
" or toggle between empty and ticked checkboxes
" let g:md_checkswitch_style = 'cycle' "'cycle' or 'toggle'


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
"let g:SignatureMap = {
        "\ 'Leader'             :  "m",
        "\ 'PlaceNextMark'      :  "m,",
        "\ 'ToggleMarkAtLine'   :  "mm",
        "\ 'PurgeMarksAtLine'   :  "dm-",
        "\ 'DeleteMark'         :  "dm",
        "\ 'PurgeMarks'         :  "dm/",
        "\ 'PurgeMarkers'       :  "dm?",
        "\ 'GotoNextLineAlpha'  :  "mn",
        "\ 'GotoPrevLineAlpha'  :  "",
        "\ 'GotoNextSpotAlpha'  :  "",
        "\ 'GotoPrevSpotAlpha'  :  "",
        "\ 'GotoNextLineByPos'  :  "",
        "\ 'GotoPrevLineByPos'  :  "",
        "\ 'GotoNextSpotByPos'  :  "mn",
        "\ 'GotoPrevSpotByPos'  :  "mp",
        "\ 'GotoNextMarker'     :  "",
        "\ 'GotoPrevMarker'     :  "",
        "\ 'GotoNextMarkerAny'  :  "",
        "\ 'GotoPrevMarkerAny'  :  "",
        "\ 'ListLocalMarks'     :  "m/",
        "\ 'ListLocalMarkers'   :  "m?"
        "\ }
map gm ]`
map gM [`
map shm :help Signature<CR>
nnoremap 'A 'Azz
nnoremap 'S 'Szz
nnoremap 'D 'Dzz
nnoremap 'F 'Fzz

" Open up lazygit
" noremap \g :Git
" noremap <leader>gg :tabe<CR>:-tabmove<CR>:term lazygit<CR>
let g:lazygit_floating_window_winblend = 0 " transparency of floating window
let g:lazygit_floating_window_scaling_factor = 0.9 " scaling factor for floating window
let g:lazygit_floating_window_corner_chars = ['╭', '╮', '╰', '╯'] " customize lazygit popup window corner characters
let g:lazygit_floating_window_use_plenary = 0 " use plenary.nvim to manage floating window if available
let g:lazygit_use_neovim_remote = 1 " fallback to 0 if neovim-remote is not installed
nnoremap <silent> <leader>gg :LazyGit<CR>
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
"let g:gitgutter_sign_added = '▎'
let g:gitgutter_sign_added = '▍'
"let g:gitgutter_sign_modified = '░'
let g:gitgutter_sign_modified = '▍'
let g:gitgutter_sign_removed = '▶'
let g:gitgutter_sign_removed_first_line = '▔'
let g:gitgutter_sign_modified_removed = '▒'
highlight GitGutterAdd    guifg=#009900 ctermfg=2
highlight GitGutterChange guifg=#0099FF ctermfg=3
highlight GitGutterDelete guifg=#ff2222 ctermfg=1
" autocmd BufWritePost * GitGutter
nnoremap <leader>gf :GitGutterFold<CR>
nnoremap <leader>gp :GitGutterPreviewHunk<CR>
nnoremap <leader>gk :GitGutterPrevHunk<CR>
nnoremap <leader>gj :GitGutterNextHunk<CR>
nnoremap <leader>gu :GitGutterUndoHunk<CR>
nnoremap <leader>gd :GitGutterDiffOrig<CR>
nnoremap <leader>gb :Git blame<CR>

" ===
" === nvim-treesitter
" ===
"lua <<EOF
"require'nvim-treesitter.configs'.setup {
  "ensure_installed = {"typescript", "vue", "java", "javascript", "markdown", "markdown_inline"},     -- one of "all", "language", or a list of languages
  "highlight = {
    "enable = true,              -- false will disable the whole extension
    "disable = { "c", "rust" },  -- list of language that will be disabled
  "},
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
"let g:EasyMotion_do_mapping = 0
"let g:EasyMotion_do_shade = 0
"let g:EasyMotion_smartcase = 1
"let g:EasyMotion_startofline = 0 " keep cursor column when JK motion
"map ; <Plug>(easymotion-prefix)
"map ;j <Plug>(easymotion-j)
"map ;k <Plug>(easymotion-k)
"map ;l <Plug>(easymotion-lineforward)
"map ;h <Plug>(easymotion-linebackward)
"map ;s <Plug>(easymotion-sn)
"map ;t <Plug>(easymotion-tn)
"map ;w <Plug>(easymotion-bd-w)
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
" === vim-illuminate
" ===
" let g:Illuminate_delay = 750
" hi illuminatedWord cterm=undercurl gui=undercurl

" ===
" === Vista.vim
" ===
" noremap <LEADER>v :Vista!!<CR>
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
let g:auto_save = 1  " enable AutoSave on Vim startup
let g:auto_save_silent = 1  " do not display the auto-save notification
"let g:auto_save = 0
"augroup ft_markdown
"  au!
"  au FileType markdown let b:auto_save = 1
"  au FileType java let b:auto_save = 1
"augroup END



" ===
" === wildfire
" ===
" let g:wildfire_objects = ["i'", 'i"', "i)", "i]", "i}", "ip", "it"]

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
" === airblade/vim-rooter
" ===
let g:rooter_patterns = ['.git/']
nnoremap <silent> <leader>tr :RooterToggle<cr>

" ===
" === jiangmiao/auto-pairs
" ===
let g:AutoPairsShortcutToggle = '<A-a>'

" ===
" === phaazon/hop.nvim
" ===
" lua require'hop'.setup { keys = 'etovxqpdygfblzhckisuran', jump_on_sole_occurrence = true }
" noremap ;w <cmd>HopWord<cr>
" noremap ;a <cmd>HopAnywhere<cr>
" noremap ;s <cmd>HopChar2<cr>
" noremap ;l <cmd>HopWordCurrentLineAC<cr>
" noremap ;h <cmd>HopWordCurrentLineBC<cr>
" noremap ;k <cmd>HopLineBC<cr>
" noremap ;j <cmd>HopLineAC<cr>
" noremap f <cmd>lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.AFTER_CURSOR, current_line_only = true })<cr>
" noremap F <cmd>lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.BEFORE_CURSOR, current_line_only = true })<cr>


lua << EOF
require('init')
EOF
