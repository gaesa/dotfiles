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
autocmd("FileType", { pattern = { "gitcommit", }, command = [[normal! gg]] })
autocmd("BufWinEnter", { command = [[normal! zz]] })

-- Remove all trailing whitespace
autocmd("BufWritePre", { pattern = { "*" }, command = [[silent! %s/\s\+$//e]] })

-- Formatter ('gg=G' is not smart, don't use it)
-- Should be placed before 'Retab' as some formatters don't support space indent
vim.api.nvim_create_autocmd("BufWritePre", { pattern = { "*" }, command = [[silent! NullFormat]] })

-- Retab
autocmd("BufWritePre", { pattern = { "*" }, command = [[silent! %retab]] })

-- Automatically enable spell checking in specific files
autocmd("FileType", { pattern = { "markdown", "gitcommit" }, command = [[set spell]] })
