-- local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Return to last edited postition
autocmd(
    "BufReadPost",
    { command = [[if line("'\"") > 1 && line("'\"") <= line("$") | execute "normal! g`\"" | endif]] }
)

-- Remove all trailing whitespace
autocmd("BufWritePre", { pattern = { "*" }, command = [[silent! %s/\s\+$//e]] })

-- Retab
autocmd("BufWritePre", { pattern = { "*" }, command = [[silent! %retab]] })
