-- Encoding
vim.opt.fileencodings = "ucs-bom,utf-8,gbk,sjis,euc-jp,big5,gb18030,latin1"
-- EOL
vim.opt.fileformats = "unix,dos,mac"

-- Line number
vim.opt.nu = true
vim.opt.rnu = true

-- Reduce keycode delay
vim.opt.timeoutlen = 1000
vim.opt.ttimeoutlen = 50

-- System clipboard
-- vim.opt.clipboard = 'unnamedplus'

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

-- History files
-- vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.local/state/nvim/undo"
vim.opt.undofile = true

-- Speel check
vim.opt.spelllang = "en,cjk"

-- Stop icons from moving my screen
vim.opt.signcolumn = "number"

-- vim.opt.scrolloff = 8
