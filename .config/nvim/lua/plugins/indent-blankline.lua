return {
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        event = "VeryLazy",
        opts = { indent = { char = "│" }, scope = { enabled = false } },
        config = function(_, opts)
            local hooks = require("ibl.hooks") -- must be set before setup() to initialize hook functions
            hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_space_indent_level)
            require("ibl").setup(opts)

            -- https://github.com/lukas-reineke/indent-blankline.nvim/pull/685
            vim.api.nvim_create_autocmd("ColorScheme", {
                callback = function()
                    vim.api.nvim_set_hl(0, "IblIndent", vim.api.nvim_get_hl(0, { name = "Whitespace" }))
                    require("ibl.highlights").setup()
                end,
                group = vim.api.nvim_create_augroup("plugins.indent-blankline@fix-color-refresh", {}),
            })
        end,
    },
}
