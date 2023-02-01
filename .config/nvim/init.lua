-- Speel check
vim.opt.spelllang = 'en,cjk'
vim.api.nvim_create_autocmd(
    "FileType",
    { pattern =  { 'markdown', 'gitcommit' }, command = [[set spell]]}
)

-- Line number
vim.opt.nu = true
vim.opt.rnu = true

-- Theme
if vim.env.TERM ~= 'linux' then
    vim.opt.termguicolors = true
    -- vim.cmd([[let g:everforest_better_performance = 1]])
    vim.g.everforest_better_performance = 1
    -- vim.g.everforest_background = 'soft'
    -- if vim.fn.strftime("%H:%M")
    if os.date('%H:%M') > '06:00' and os.date('%H:%M') < '18:00' then
        vim.opt.background = 'light'
        vim.cmd([[colorscheme everforest]])
        vim.opt.cursorline = true
    else
        vim.opt.background = 'dark'
        -- Blow two lines code produce different effects
        -- Maybe related features are not 100% exposed to Lua yet
        -- vim.g.erverforest_transparent_background = 1
        vim.cmd([[let g:everforest_transparent_background = 1]])
        vim.cmd([[colorscheme everforest]])
        vim.opt.cursorlineopt = 'number'
        vim.opt.cursorline = true
    end
    if vim.o.diff == true then
        vim.opt.cursorline = false
    end
else
    vim.cmd([[colorscheme habamax]])
    if vim.o.diff == true then
        vim.cmd([[colorscheme default]])
    end
    vim.g.loaded_airline = 1
end

-- Search
vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- TAB/Indent
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- System clipboard
vim.opt.clipboard = 'unnamedplus'

-- Return to last edited postition
vim.api.nvim_create_autocmd(
    "BufReadPost",
    { command = [[if line("'\"") > 1 && line("'\"") <= line("$") | execute "normal! g`\"" | endif]] }
)
-- Remove all trailing whitespace
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    pattern = { "*" },
    command = [[%s/\s\+$//e]],
})

-- Reduce keycode delay
vim.opt.timeoutlen = 1000
vim.opt.ttimeoutlen = 50

-- Remap
vim.keymap.set('n', 'j', 'gj', { noremap = true })
vim.keymap.set('n', 'gj', 'j', { noremap = true })
vim.keymap.set('n', 'k', 'gk', { noremap = true })
vim.keymap.set('n', 'gk', 'k', { noremap = true })
-- clear last search highlighting
vim.keymap.set('n', '<CR>', ':nohls<CR><CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<C-s>', '<ESC>:xa<CR>', { noremap = true })
vim.keymap.set('i', '<C-s>', '<ESC>:xa<CR>', { noremap = true })
if vim.o.diff == true then
    vim.keymap.set('n', '<C-q>', '<ESC>:cq<CR>', { noremap = true })
    vim.keymap.set('i', '<C-q>', '<ESC>:cq<CR>', { noremap = true })
else
    vim.keymap.set('n', '<C-q>', '<ESC>:qa!<CR>', { noremap = true })
    vim.keymap.set('i', '<C-q>', '<ESC>:qa!<CR>', { noremap = true })
end
-- toggle spell checking
vim.keymap.set('n', '<F11>', '<ESC>:set spell!<CR>', { noremap = true, silent = true })
vim.keymap.set('i', '<F11>', '<ESC>:set spell!<CR>', { noremap = true, silent = true })
