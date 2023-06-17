local map = vim.keymap.set

-- Builtin file explorer
map({ "n" }, "<leader>fm", vim.cmd.Ex)

-- Intuitively move cursor
map({ "x" }, "J", ":m '>+1<CR>gv=gvzz")
map({ "x" }, "K", ":m '<-2<CR>gv=gvzz")
map({ "n" }, "J", "mzJ`z") -- allow the cursor to remain in the same position
map({ "n", "x" }, "j", "gjzz")
map({ "n", "x" }, "k", "gkzz")
map({ "n", "x" }, "gj", "j")
map({ "n", "x" }, "gk", "k")

-- Automatically center screen on current line (zz)
map({ "n" }, "<C-d>", "<C-d>zz")
map({ "n" }, "<C-u>", "<C-u>zz")
map({ "n" }, "<C-o>", "<C-o>zz")
map({ "n" }, "<C-i>", "<C-i>zz")
map({ "n" }, "n", "nzzzv")
map({ "n" }, "N", "Nzzzv")
map({ "n" }, "*", "*zzzv")
map({ "n" }, "#", "#zzzv")
map({ "n" }, "G", "Gzz")

-- Emacs-like keybinding
map({ "i", "c", "t" }, "<C-a>", "<Home>")
map({ "i", "c", "t" }, "<C-e>", "<End>")
map({ "i", "t" }, "<C-b>", "<Left>")
map({ "i", "t" }, "<C-f>", "<Right>")
map({ "i", "c", "t" }, "<C-p>", "<Up>")
map({ "i", "c", "t" }, "<C-n>", "<Down>")
map({ "i", "c", "t" }, "<A-b>", "<S-Left>")
map({ "i", "c", "t" }, "<A-f>", "<S-Right>")
map({ "i" }, "<A-d>", function()
    vim.cmd.normal({ args = { "de" }, bang = true })
end)
map({ "i" }, "<C-u>", function()
    -- cmap, tmap don't work
    vim.cmd.normal({ args = { "d^" }, bang = true })
end)
map({ "i" }, "<C-k>", function()
    -- vim.cmd.normal({ args = { "d$" }, bang = true })
    -- the position of cursor can't be fixed
    local pos = vim.api.nvim_win_get_cursor(0)
    local row = pos[1]
    local col = pos[2]
    local len = #vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1]
    local str = vim.api.nvim_buf_get_text(0, row - 1, col, row - 1, len, {})[1]
    vim.fn.setreg('"', str, "c")
    vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, len, {})
end)

-- Clipboard
map({ "n", "x" }, "<leader>p", [["+p]])
map({ "n", "x" }, "<leader>P", [["+P]])
map({ "n", "x" }, "<leader>y", [["+y]])
map({ "n" }, "<leader>Y", [["+y$]])
map({ "n", "x" }, "<leader>d", [["+d]])
map({ "n" }, "<leader>D", [["+D]])
map({ "n", "x" }, "<leader>c", [["+c]])
map({ "n" }, "<leader>C", [["+C]])
-- map({ "x" }, "<leader>p", [["_dP]])
-- map({ "n", "x" }, "<leader>d", [["_d]])

-- Automatically create a new file as necessary
map({ "n" }, "gf", ":e <cfile><CR>", { silent = true })

-- Quit and Save
map({ "n" }, "q", ":q<CR>", { silent = true })
map({ "n" }, "Q", "q", { silent = true })
map({ "n", "i" }, "<C-q>", "<Esc>:qa!<CR>", { silent = true })
map({ "n", "i" }, "<C-s>", "<Esc>:xa<CR>", { silent = true })

-- Make files executable
map({ "n" }, "<leader>x", function()
    local file = vim.api.nvim_buf_get_name(0)
    vim.fn.jobstart({ "chmod", "u+x", file })
end)

-- Clears and redraws screen, clears search highlighting and then zz
map({ "n" }, "<Enter>", "<C-l>:noh<CR>zz<Enter>", { silent = true })

-- Toggle spell checking
map({ "n", "i" }, "<F11>", function()
    vim.wo.spell = not vim.wo.spell
end)

-- QuickFix
map({ "n" }, "<C-j>", "<cmd>cnext<CR>zz")
map({ "n" }, "<C-k>", "<cmd>cprev<CR>zz")
map({ "n" }, "<leader>j", "<cmd>lnext<CR>zz")
map({ "n" }, "<leader>k", "<cmd>lprev<CR>zz")

-- Substitude
map({ "n" }, "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- FZF
map({ "n" }, "<C-f>", function()
    vim.cmd.FZF()
end)

-- Surround
map({ "n" }, "s", "<NOP>")

-- GitHub
map({ "n" }, "<leader>gh", function()
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
end, { silent = true })
