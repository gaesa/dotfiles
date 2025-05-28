-- Bootstrap
local vim_data_dir = vim.fn.stdpath("data") ---@cast vim_data_dir string
local lazypath = vim.fs.joinpath(vim_data_dir, "lazy", "lazy.nvim")
if vim.uv.fs_stat(lazypath) == nil then ---@diagnostic disable-line: undefined-field
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

local opts = {
    defaults = { lazy = true },
    checker = { enable = true, frequency = 604800 },
    performance = {
        cache = {
            enabled = true,
        },
        reset_packpath = true, -- reset the package path to improve startup time
    },
}

require("lazy").setup("plugins", opts)
