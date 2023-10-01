return {
    {
        "iamcco/markdown-preview.nvim",
        ft = "markdown",
        event = "VeryLazy",
        build = function()
            vim.fn["mkdp#util#install"]()
        end,
    },
}
