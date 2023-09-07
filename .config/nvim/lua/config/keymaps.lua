local map = vim.keymap.set

-- Builtin file explorer
map({ "n" }, "<leader>fm", vim.cmd.Ex)

-- Window
map({ "n" }, "<leader>w", "<C-w>")

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

-- Easier to press
map({ "n", "x", "o" }, "H", "g^")
map({ "n", "x", "o" }, "L", "g$")
map({ "n", "x", "o" }, "gT", "H")
map({ "n", "x", "o" }, "gB", "L")
map({ "n", "x", "o" }, "<A-d>", "%zz")

-- Emacs-like keybinding
local function get_cur_pos()
    local pos = vim.api.nvim_win_get_cursor(0)
    local row = pos[1] - 1
    local col = pos[2]
    return row, col
end
local function all_blank_before_cursor(row, col)
    local str = vim.api.nvim_buf_get_text(0, row, 0, row, col, {})[1]
    local blank_space = { [" "] = true, ["\t"] = true }
    for i = 1, #str, 1 do
        local char = string.sub(str, i, i)
        if not blank_space[char] then
            return false
        end
    end
    return true
end
local function need_goto_start(row, col)
    if col == 0 then
        return false
    else
        return all_blank_before_cursor(row, col)
    end
end
map({ "c", "t" }, "<C-a>", "<Home>")
map({ "i" }, "<C-a>", function()
    local row, col = get_cur_pos()
    if need_goto_start(row, col) then
        vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
    else
        vim.cmd.normal({ args = { "^" }, bang = true })
    end
end)
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
local function press_backspace()
    local key = vim.api.nvim_replace_termcodes("<BS>", true, false, true)
    vim.api.nvim_feedkeys(key, "n", false)
end
map({ "i" }, "<C-u>", function() -- cmap, tmap don't work
    local row, col = get_cur_pos()
    if col == 0 then
        -- `nvim_win_set_cursor` can't set cursor to after last character
        press_backspace()
    else
        if all_blank_before_cursor(row, col) then
            vim.cmd.normal({ args = { "d0" }, bang = true })
        else
            vim.cmd.normal({ args = { "d^" }, bang = true })
        end
    end
end)
map({ "i" }, "<C-k>", function()
    -- The position of cursor can't be corrected by:
    -- vim.cmd.normal({ args = { "d$" }, bang = true })
    local row, col = get_cur_pos()
    local len = #vim.api.nvim_buf_get_lines(0, row, row + 1, true)[1]
    local str = vim.api.nvim_buf_get_text(0, row, col, row, len, {})[1]
    if str == "" then
        local line = vim.api.nvim_buf_line_count(0)
        if row == line - 1 then
            return
        else
            vim.api.nvim_win_set_cursor(0, { row + 2, 0 })
            press_backspace()
        end
    else
        vim.fn.setreg('"', str, "c")
        vim.api.nvim_buf_set_text(0, row, col, row, len, {})
    end
end)

-- Clipboard
map({ "n", "x" }, "<leader>y", [["+]])
-- map({ "x" }, "<leader>p", [["_dP]])
-- map({ "n", "x" }, "<leader>d", [["_d]])

-- Automatically create a new file as necessary
map({ "n" }, "gf", ":e <cfile><CR>", { silent = true })

-- Quit and Save
map({ "n" }, "q", ":q<CR>", { silent = true })
map({ "n" }, "Q", "q", { silent = true })
map({ "n", "i" }, "<C-q>", "<Esc>:qa!<CR>", { silent = true })
map({ "n", "i" }, "<C-s>", "<Esc>:xa<CR>", { silent = true })
map({ "n" }, "<leader>fs", function()
    vim.cmd.up({ args = {}, bang = true })
end)

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

-- Buffers
map({ "n" }, "<leader>bn", function()
    vim.cmd.bnext()
end)
map({ "n" }, "<leader>bN", function()
    vim.cmd.bprev()
end)

-- QuickFix
map({ "n" }, "<C-j>", "<cmd>cnext<CR>zz")
map({ "n" }, "<C-k>", "<cmd>cprev<CR>zz")
map({ "n" }, "<leader>j", "<cmd>lnext<CR>zz")
map({ "n" }, "<leader>k", "<cmd>lprev<CR>zz")

-- Substitude
map({ "n" }, "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Manual
map({ "n" }, "<leader>so", function()
    local input = vim.fn.input("Search option: ")
    vim.fn.search([[^\s*]] .. input, "wz")
end)

-- FZF
map({ "n" }, "<C-f>", function()
    vim.cmd.FZF()
end)

-- Surround
map({ "n" }, "s", "<NOP>")

-- GitHub
map({ "n" }, "<leader>gh", function()
    local line = vim.api.nvim_get_current_line()
    local pattern = [=[["'][%w%-_%.]+/[%w%-_%.]+["']]=]
    local match = string.match(line, pattern)

    if match ~= nil then
        local link = "https://github.com/" .. string.sub(match, 2, -2)
        vim.fn.jobstart({ "xdg-open", link }, { detach = true })
    else
        print("No GitHub link found")
    end
end, { silent = true })
