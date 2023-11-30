local opts = {
    focus_outline = false,
    outline_window = {
        position = "left",
        width = 12,
    },
    preview_window = {
        auto_preview = false,
        open_hover_on_preview = true,
        -- Experimental feature that let's you edit the source content live
        -- in the preview window. Like VS Code's "peek editor".
        live = false,
    },
    symbols = {},
}

return {
    {
        "hedyhli/outline.nvim",
        cond = not vim.g.vscode,
        cmd = { "Outline", "OutlineOpen" },
        keys = { -- Example mapping to toggle outline
            {
                "<leader>o",
                function()
                    require("outline").toggle(opts)
                end,
                desc = "Toggle outline",
            },
        },
        opts = opts,
    },
}
