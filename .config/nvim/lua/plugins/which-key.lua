return {
    {
        "folke/which-key.nvim", -- for spell check
        cond = false, -- often makes `noice.nvim`'s routes fail
        event = "VeryLazy",
        opts = {
            plugins = {
                marks = true, -- shows a list of your marks on ' and `
                registers = true,
                spelling = {
                    enabled = true,
                    suggestions = 10,
                },
                presets = {
                    operators = false, -- affect routes of `noice`
                    motions = false,
                    text_objects = false,
                    windows = false,
                    nav = false,
                    z = false,
                    g = false,
                },
            },
            window = {
                border = "single",
                position = "top",
                margin = { 0, 0, 0, 0 },
                padding = { 0, 0, 0, 0 },
            },
            layout = {
                height = { min = 1, max = 25 },
                width = { min = 1, max = 25 },
                spacing = 2, -- spacing between columns
                align = "center",
            },
            ignore_missing = true,
            show_help = false,
            show_keys = false,
        },
    },
}
