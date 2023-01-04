" line number
set nu! rnu!	" show absolute and relative number at the same time

" theme
if $TERM != "linux"
	let g:everforest_better_performance = 1
	set termguicolors
	if strftime("%H:%M") > "05:30" && strftime("%H:%M") < "18:00"
		set background=light
		colorscheme everforest
		set cursorline!
	else
		set background=dark
		let g:everforest_transparent_background = 1
		colorscheme everforest
		highlight CursorLine cterm=NONE ctermbg=NONE ctermfg=NONE guibg=NONE guifg=NONE
		set cursorline!
	endif
	if &diff
		set cursorline!
	endif
else
	colorscheme habamax
	if &diff
		colorscheme default
	endif
	let g:loaded_airline = 1
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

