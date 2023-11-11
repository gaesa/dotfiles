return {
    {
        "kevinhwang91/nvim-ufo",
        cond = not vim.g.vscode,
        dependencies = "kevinhwang91/promise-async",
        event = "VeryLazy",
        config = function()
            vim.opt.foldenable = true
            vim.opt.foldcolumn = "0" -- '0' is not bad
            vim.opt.foldlevelstart = 99

            -- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
            vim.keymap.set("n", "zR", require("ufo").openAllFolds)
            vim.keymap.set("n", "zM", require("ufo").closeAllFolds)
            require("ufo").setup({
                provider_selector = function(_, _, _)
                    return { "treesitter", "indent" }
                end,
            })

            local function fix_diff_fold()
                if vim.wo.diff then
                    return
                else
                    vim.opt.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
                end
            end
            vim.api.nvim_create_autocmd({ "BufEnter" }, {
                callback = fix_diff_fold,
                group = vim.api.nvim_create_augroup("plugins.nvim-ufo@fix-diff-fold", {}),
            })
        end,
    },
}
