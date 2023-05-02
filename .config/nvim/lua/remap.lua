local map = vim.keymap.set

-- Builtin file explorer
map("n", "<leader>fm", vim.cmd.Ex)

-- Intuitively move cursor
map("x", "J", ":m '>+1<CR>gv=gvzz")
map("x", "K", ":m '<-2<CR>gv=gvzz")
map("n", "J", "mzJ`z") -- allow the cursor to remain in the same position
map({ "n", "x" }, "j", "gjzz", { noremap = true })
map({ "n", "x" }, "k", "gkzz", { noremap = true })
map({ "n", "x" }, "gj", "j", { noremap = true })
map({ "n", "x" }, "gk", "k", { noremap = true })

-- Automatically center screen on current line (zz)
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "<C-o>", "<C-o>zz")
map("n", "<C-i>", "<C-i>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")
map("n", "*", "*zzzv")
map("n", "#", "#zzzv")
map("n", "G", "Gzz", { noremap = true })

-- Clipboard
map({ "n", "x" }, "<leader>p", [["+p]])
map({ "n", "x" }, "<leader>P", [["+P]])
map({ "n", "x" }, "<leader>y", [["+y]])
map({ "n" }, "<leader>Y", [["+y$]])
map({ "n", "x" }, "<leader>d", [["+d]])
map({ "n" }, "<leader>D", [["+D]])
map({ "n", "x" }, "<leader>c", [["+c]])
map({ "n" }, "<leader>C", [["+C]])
-- map("x", "<leader>p", [["_dP]])
-- map({ "n", "x" }, "<leader>d", [["_d]])

-- Automatically create a new file as necessary
map("n", "gf", ":e <cfile><CR>", { noremap = true, silent = true })

-- Quit and Save
if vim.wo.diff == true then
    map({ "n", "i" }, "<C-q>", "<ESC>:cq<CR>", { noremap = true })
    map("n", "Q", "<ESC>:q<CR>", { silent = true })
else
    map({ "n", "i" }, "<C-q>", "<ESC>:qa!<CR>", { noremap = true })
    map("n", "Q", "<ESC>:q<CR>", { silent = true })
end
map({ "n", "i" }, "<C-s>", "<ESC>:xa<CR>", { noremap = true })

-- Make files executable
map("n", "<leader>x", "<cmd>!chmod u+x %<CR><Enter>", { noremap = true, silent = true })

-- Clears and redraws screen, clears search highlighting and then zz
map("n", "<Enter>", "<C-l>:noh<CR>zz<Enter>", { noremap = true, silent = true })

-- Toggle spell checking
map("n", "<F11>", "<ESC>:set spell!<CR>", { noremap = true, silent = true })
map("i", "<F11>", "<ESC>:set spell!<CR>a", { noremap = true, silent = true })

-- QuickFix
map("n", "<C-j>", "<cmd>cnext<CR>zz")
map("n", "<C-k>", "<cmd>cprev<CR>zz")
map("n", "<leader>j", "<cmd>lnext<CR>zz")
map("n", "<leader>k", "<cmd>lprev<CR>zz")

-- Substitude
map("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- FZF
vim.keymap.set({ "n", "i" }, "<C-f>", "<ESC>:FZF<CR>", { noremap = true, silent = true })
