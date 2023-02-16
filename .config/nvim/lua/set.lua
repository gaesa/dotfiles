-- Hide intro message
vim.opt.shortmess:append("I")

-- Show filename as window title
vim.opt.title = true

-- Hide tilde "~" at the start of nonexistent line
vim.opt.fillchars:append("eob: ")

-- Encoding
vim.opt.fileencodings = "ucs-bom,utf-8,gbk,sjis,euc-jp,big5,gb18030,latin1"
-- EOL
vim.opt.fileformats = "unix,dos,mac"

-- Line number
vim.opt.nu = true
vim.opt.rnu = true

-- Code folding
vim.opt.foldmethod = "indent"
vim.opt.foldenable = false
vim.opt.foldlevel = 10
vim.opt.foldnestmax = 10

-- Reduce keycode delay
vim.opt.timeoutlen = 1000
vim.opt.ttimeoutlen = 50

-- System clipboard
-- vim.opt.clipboard = "unnamedplus"

-- TAB/Indent
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- Search
vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- History files
vim.opt.history = 1000
-- vim.opt.swapfile = false
vim.opt.backup = false

-- Spell check
vim.opt.spelllang = "en,cjk"
