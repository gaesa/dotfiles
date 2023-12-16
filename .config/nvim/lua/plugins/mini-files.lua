return {
    {
        "echasnovski/mini.files",
        cond = not vim.g.vscode,
        version = false,
        lazy = false,
        config = function()
            require("mini.files").setup()
            vim.keymap.set({ "n" }, "<leader>fm", "<cmd>lua MiniFiles.open()<cr>")
        end,
    },
}
