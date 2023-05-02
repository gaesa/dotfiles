-- local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Toggle absolute and relative numbering by insert/normal mode
autocmd("InsertEnter", { command = [[set nornu]] })
autocmd("InsertLeave", { command = [[set rnu]] })

-- Yank selection to primary clipboard automatically
-- limitation: in some cases, this autocmd doesn't work, for example,
-- when the cursor is at the end of a word, after pressing `viw`, only the last character is yanked
-- related pull: https://github.com/neovim/neovim/pull/13896#issuecomment-774680224
-- related post: https://vi.stackexchange.com/questions/36692/vimscript-how-to-detect-selection-of-a-text-object-in-visual-mode
autocmd({ "CursorMoved", "ModeChanged" }, {
    pattern = "*",
    callback = function()
        local mode = string.sub(vim.api.nvim_get_mode().mode, 1, 1)
        if mode ~= "v" and mode ~= "V" then
            return
        else
            vim.cmd([[normal! "*y]])
            vim.cmd([[normal! gv]])
        end
    end,
})

-- Return to last edited postition
autocmd(
    "BufReadPost",
    { command = [[if line("'\"") > 1 && line("'\"") <= line("$") | execute "normal! g`\"" | endif]] }
)
autocmd("FileType", { pattern = { "gitcommit" }, command = [[normal! gg]] })
autocmd("BufWinEnter", { command = [[normal! zz]] })

-- Remove all trailing whitespace
autocmd("BufWritePre", { pattern = { "*" }, command = [[silent! %s/\s\+$//e]] })

-- Formatter ('gg=G' is not smart, don't use it)
-- Should be placed before 'Retab' as some formatters don't support space indent
autocmd("BufWritePre", { pattern = { "*" }, command = [[lua vim.lsp.buf.format({async = false})]] })

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
    if vim.v.hlsearch ~= 0 then
        local keycode = vim.api.nvim_replace_termcodes("<Cmd>nohl<CR>", true, false, true)
        vim.api.nvim_feedkeys(keycode, "n", false)
    else
        return
    end
end
local function start_hl()
    local res = vim.fn.getreg("/")
    if vim.v.hlsearch == 1 and vim.fn.search([[\%#\zs]] .. res, "cnW") == 0 then
        stop_hl()
    else
        return
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
