return {
    {
        "echasnovski/mini.surround",
        version = false,
        event = "VeryLazy",
        config = function()
            require("mini.surround").setup({
                -- See also: https://github.com/echasnovski/mini.nvim/issues/128
                custom_surroundings = {
                    ["("] = { input = { "%b()", "^.().*().$" }, output = { left = "(", right = ")" } },
                    ["["] = { input = { "%b[]", "^.().*().$" }, output = { left = "[", right = "]" } },
                    ["{"] = { input = { "%b{}", "^.().*().$" }, output = { left = "{", right = "}" } },
                    ["<"] = { input = { "%b<>", "^.().*().$" }, output = { left = "<", right = ">" } },
                },
            })
        end,
    },
}
