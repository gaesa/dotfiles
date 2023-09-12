return {
    {
        "lukas-reineke/indent-blankline.nvim",
        lazy = false,
        opts = {
            -- char = "┊",
            show_first_indent_level = false,
            show_trailing_blankline_indent = false,
        },
        config = function(_, opts)
            require("indent_blankline").setup(opts)

            -- Disable indent-blankline for some filetypes
            local excluded_files = { "scheme", "lisp" }

            local autocmd = vim.api.nvim_create_autocmd
            local group = vim.api.nvim_create_augroup("plugins.indent-blankline", { clear = true })

            autocmd({ "FileType" }, {
                pattern = excluded_files,
                callback = function()
                    require("indent_blankline").setup({
                        enabled = false,
                    })
                end,
                group = group,
            })
        end,
    },
}
