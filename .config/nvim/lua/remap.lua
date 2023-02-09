vim.g.mapleader = " "
vim.keymap.set("n", "<leader>fm", vim.cmd.Ex)
vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25

-- Intuitively move cursor
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("n", "j", "gjzz", { noremap = true })
vim.keymap.set("n", "k", "gkzz", { noremap = true })
vim.keymap.set("n", "gj", "j", { noremap = true })
vim.keymap.set("n", "gk", "k", { noremap = true })

-- zz
-- alow cursor in the same place
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Clipboard
vim.keymap.set("n", "<leader>p", [["+p]])
vim.keymap.set("n", "<leader>P", [["+P]])
vim.keymap.set("x", "<leader>p", [["_dP]])
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set({ "n", "v" }, "<leader>Y", [["+Y]])
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

-- Clear last search highlighting
vim.keymap.set("n", "<CR>", ":nohls<CR><CR>", { noremap = true, silent = true })

-- Quit and Save
-- vim.keymap.set('n', 'Q', '<nop>')
vim.keymap.set("n", "Q", "<ESC>:q<CR>")
vim.keymap.set("n", "W", "<ESC>:up<CR>")
if vim.o.diff == true then
    vim.keymap.set({ "n", "i" }, "<C-q>", "<ESC>:cq<CR>", { noremap = true })
else
    vim.keymap.set({ "n", "i" }, "<C-q>", "<ESC>:qa!<CR>", { noremap = true })
end
vim.keymap.set({ "n", "i" }, "<C-s>", "<ESC>:xa<CR>", { noremap = true })

-- Toggle spell checking
vim.keymap.set("n", "<F11>", "<ESC>:set spell!<CR>", { noremap = true, silent = true })
vim.keymap.set("i", "<F11>", "<ESC>:set spell!<CR>a", { noremap = true, silent = true })

-- QuickFix
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

-- Substitude
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- FZF
vim.keymap.set({ "n", "i" }, "<C-f>", "<ESC>:FZF<CR>", { noremap = true, silent = true })