-- local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Toggle absolute and relative numbering by insert/normal mode
autocmd("InsertEnter", { command = [[set nornu]] })
autocmd("InsertLeave", { command = [[set rnu]] })

-- Return to last edited postition
autocmd(
    "BufReadPost",
    { command = [[if line("'\"") > 1 && line("'\"") <= line("$") | execute "normal! g`\"" | endif]] }
)
autocmd("FileType", { pattern = { "gitcommit" }, command = [[normal! gg]] })
autocmd("BufWinEnter", { command = [[normal! zz]] })

-- Remove all trailing whitespace
autocmd("BufWritePre", { pattern = { "*" }, command = [[silent! %s/\s\+$//e]] })

-- Retab
autocmd("BufWritePre", { pattern = { "*" }, command = [[silent! %retab]] })

-- Automatically enable spell checking in specific files
autocmd("FileType", { pattern = { "markdown", "gitcommit" }, command = [[set spell]] })

-- Automatically change shortcuts in specific files
autocmd("FileType", {
    pattern = "gitcommit",
    callback = function()
        vim.keymap.set({ "n", "i" }, "<C-q>", "<ESC>:cq<CR>", { noremap = true })
        vim.keymap.set("n", "Q", "<ESC>:cq<CR>", { silent = true })
    end,
})

-- Highlight yanked text
autocmd("TextYankPost", {
    pattern = "*",
    callback = function()
        vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
    end,
})

-- Automatically disable search highlight
-- https://github.com/glepnir/hlsearch.nvim
local function stop_hl()
    if vim.v.hlsearch == 0 then
        return
    end
    local keycode = vim.api.nvim_replace_termcodes("<Cmd>nohl<CR>", true, false, true)
    vim.api.nvim_feedkeys(keycode, "n", false)
end

local function start_hl()
    local res = vim.fn.getreg("/")
    if vim.v.hlsearch == 1 and vim.fn.search([[\%#\zs]] .. res, "cnW") == 0 then
        stop_hl()
    end
end

autocmd("InsertEnter", {
    callback = function()
        stop_hl()
    end,
    desc = "Auto remove hlsearch",
})
autocmd("CursorMoved", {
    callback = function()
        start_hl()
    end,
    desc = "Auto hlsearch",
})

-- Quit with 'q'
autocmd(
    "FileType",
    { pattern = { "help", "man", "startuptime", "qf" }, command = [[nnoremap <buffer><silent> q :quit<CR>]] }
)
