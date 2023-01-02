" basic
set nocompatible	" avoid some problems on some platforms
set nomodeline		" security tweak
set nu! rnu!	" show absolute and relative number at the same time
" set nu!

" theme
set termguicolors
if strftime("%H") >= 5 && strftime("%H") < 18
	set background=light
else
	set background=dark
	let g:everforest_transparent_background = 1
endif
let g:everforest_better_performance = 1
colorscheme everforest

highlight CursorLine cterm=NONE ctermbg=NONE ctermfg=NONE guibg=NONE guifg=NONE
set cursorline!
if &diff
	set cursorline!
endif

" search
set incsearch	" do incremental searching, search as you type
set hlsearch	" highlight searches
set ignorecase	" ignore case when searching	
set smartcase	" no ignorecase if Uppercase char present

" indent
set autoindent smartindent shiftround
set tabstop=4
set shiftwidth=4
set softtabstop=4	" insert mode tab and backspace use 4 spaces

" use system clipboard
set clipboard+=unnamedplus

" return to last edit position when opening files
autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal! g`\"" |
    \ endif

" reduce keycode delay
set timeoutlen=1000
set ttimeoutlen=50

" remap
nnoremap j gj
nnoremap gj j
nnoremap k gk
nnoremap gk k

" plugin manager
lua require('plugins')

