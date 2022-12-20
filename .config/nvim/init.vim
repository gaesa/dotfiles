" basic
set nocompatible	" avoid some problems on some platforms
set nomodeline		" security tweak
set nu! rnu!	" show absolute and relative number at the same time
" set nu!
syntax on
"set termguicolors

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

