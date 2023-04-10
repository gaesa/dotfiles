-- Hide intro message
vim.opt.shortmess:append("I")

-- Show filename as window title
vim.opt.title = true

-- Hide tilde "~" at the start of nonexistent line
vim.opt.fillchars:append("eob: ")

-- Diff
-- a related issue:
-- https://github.com/neovim/neovim/issues/22696
-- vim.opt.diffopt:append({ "linematch:60" })

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

-- Mouse
-- vim.opt.mouse = "a"
-- vim.opt.selectmode = "mouse"
-- vim.opt.mousefocus = true

-- History
vim.opt.history = 1000

-- Backup/Swap
-- Default: 'backup' is off, 'writebackup' is on, 'swapfile' is on
-- vim.opt.undodir = os.getenv("HOME") .. "/.local/state/nvim/undo"
-- vim.opt.undofile = true

-- Spell check
vim.opt.spelllang = "en,cjk"
