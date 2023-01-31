" Spell check
set spelllang=en,cjk
autocmd FileType markdown,gitcommit set spell

" Line number
set nu! rnu!    " show absolute and relative number at the same time

" Theme
if $TERM != "linux"
    let g:everforest_better_performance = 1
    set termguicolors
    if strftime("%H:%M") > "05:30" && strftime("%H:%M") < "18:00"
        set background=light
        colorscheme everforest
        set cursorline
    else
        set background=dark
        let g:everforest_transparent_background = 1
        colorscheme everforest
        set cursorlineopt=number
        set cursorline
    endif
    if &diff
        set nocursorline
    endif
else
    colorscheme habamax
    if &diff
        colorscheme default
    endif
    let g:loaded_airline = 1
endif

" Search
set incsearch   " Do incremental searching, search as you type
set hlsearch    " Highlight searches
set ignorecase  " Ignore case when searching
set smartcase   " No ignorecase if uppercase char present

" TAB/Indent
set tabstop=4   " The width of a TAB is set to 4
set shiftwidth=4    " Indents will have a width of 4
set expandtab   " Expand TABs to spaces

" System clipboard
set clipboard+=unnamedplus

" Return to last edit position when opening files
autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal! g`\"" |
    \ endif

" Reduce keycode delay
set timeoutlen=1000
set ttimeoutlen=50

" Remap
nnoremap j gj
nnoremap gj j
nnoremap k gk
nnoremap gk k
" Clear last search highlighting
nnoremap <silent> <CR> :nohlsearch<CR><CR>
noremap <C-S> <ESC>:xa<CR>
inoremap <C-S> <ESC>:xa<CR>
if &diff
    noremap <C-Q> <ESC>:cq<CR>
    inoremap <C-Q> <ESC>:cq<CR>
else
    noremap <C-Q> <ESC>:qa!<CR>
    inoremap <C-Q> <ESC>:qa!<CR>
endif
" Toggle spell checking
nnoremap <silent> <F11> :set spell!<cr>
inoremap <silent> <F11> <ESC>:set spell!<cr>a

" Plugin manager
lua require('plugins')
