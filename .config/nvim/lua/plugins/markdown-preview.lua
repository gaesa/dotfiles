return {
    {
        "iamcco/markdown-preview.nvim",
        cond = not vim.g.vscode,
        ft = "markdown",
        event = "VeryLazy",
        build = function()
            vim.fn["mkdp#util#install"]()
        end,
    },
}
