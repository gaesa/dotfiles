-- Builtin file explorer
vim.keymap.set("n", "<leader>fm", vim.cmd.Ex)

-- Intuitively move cursor
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gvzz")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gvzz")
vim.keymap.set("n", "J", "mzJ`z") -- allow the cursor to remain in the same position
vim.keymap.set({ "n", "v" }, "j", "gjzz", { noremap = true })
vim.keymap.set({ "n", "v" }, "k", "gkzz", { noremap = true })
vim.keymap.set({ "n", "v" }, "gj", "j", { noremap = true })
vim.keymap.set({ "n", "v" }, "gk", "k", { noremap = true })
vim.keymap.set({ "n", "v", "o" }, "H", "g0", { noremap = true })
vim.keymap.set({ "n", "v", "o" }, "L", "g$", { noremap = true })

-- Automatically center screen on current line (zz)
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "<C-o>", "<C-o>zz")
vim.keymap.set("n", "<C-i>", "<C-i>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("n", "*", "*zzzv")
vim.keymap.set("n", "#", "#zzzv")
vim.keymap.set("n", "G", "Gzz", { noremap = true })

-- Clipboard
vim.keymap.set({ "n", "v" }, "<leader>p", [["+p]])
vim.keymap.set({ "n", "v" }, "<leader>P", [["+P]])
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set({ "n", "v" }, "<leader>Y", [["+y$]])
vim.keymap.set({ "n", "v" }, "<leader>d", [["+d]])
vim.keymap.set({ "n", "v" }, "<leader>D", [["+D]])
vim.keymap.set({ "n", "v" }, "<leader>c", [["+c]])
vim.keymap.set({ "n", "v" }, "<leader>C", [["+C]])
-- vim.keymap.set("x", "<leader>p", [["_dP]])
-- vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

-- Automatically create a new file as necessary
vim.keymap.set("n", "gf", ":e <cfile><CR>", { noremap = true, silent = true })

-- Quit and Save
if vim.wo.diff == true then
    vim.keymap.set({ "n", "i" }, "<C-q>", "<ESC>:cq<CR>", { noremap = true })
    vim.keymap.set("n", "Q", "<ESC>:q<CR>", { silent = true })
else
    vim.keymap.set({ "n", "i" }, "<C-q>", "<ESC>:qa!<CR>", { noremap = true })
    vim.keymap.set("n", "Q", "<ESC>:q<CR>", { silent = true })
end
vim.keymap.set({ "n", "i" }, "<C-s>", "<ESC>:xa<CR>", { noremap = true })

-- Make files executable
vim.keymap.set("n", "<leader>x", "<cmd>!chmod u+x %<CR><Enter>", { noremap = true, silent = true })

-- Clears and redraws screen, clears search highlighting and then zz
vim.keymap.set("n", "<Enter>", "<C-l>:noh<CR>zz<Enter>", { noremap = true, silent = true })

-- Toggle spell checking
vim.keymap.set("n", "<F11>", "<ESC>:set spell!<CR>", { noremap = true, silent = true })
vim.keymap.set("i", "<F11>", "<ESC>:set spell!<CR>a", { noremap = true, silent = true })

-- QuickFix
vim.keymap.set("n", "<C-j>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-k>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lprev<CR>zz")

-- Substitude
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- FZF
vim.keymap.set({ "n", "i" }, "<C-f>", "<ESC>:FZF<CR>", { noremap = true, silent = true })

-- GitHub
vim.keymap.set("n", "<leader>gh", function()
    local line = vim.api.nvim_get_current_line()
    --local _, pos = unpack(vim.api.nvim_win_get_cursor(0))

    local pattern = [=[["'][%w%-_%.]+/[%w%-_%.]+["']]=]
    local match = string.match(line, pattern)

    if match ~= nil then
        local link = "https://github.com/" .. string.sub(match, 2, -2)
        vim.fn.jobstart({ "xdg-open", link }, { detach = true })
    else
        print("No GitHub link found")
    end
end, { noremap = true, silent = true })
