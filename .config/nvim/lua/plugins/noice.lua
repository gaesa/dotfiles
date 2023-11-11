return {
    {
        "folke/noice.nvim",
        cond = not vim.g.vscode,
        event = "VeryLazy",
        dependencies = {
            "MunifTanjim/nui.nvim",
            {
                "rcarriga/nvim-notify",
                opts = {
                    background_colour = "#000000",
                    render = "wrapped-compact",
                    animate = false,
                    stages = "static",
                    minimum_width = 1,
                    max_width = 35,
                    timeout = 5000,
                    -- wrap = true,
                },
            },
        },
        init = function(_)
            vim.o.cmdheight = 0
        end,
        opts = {
            commands = {
                history = {
                    view = "popup",
                },
            },
            views = {
                notify = {
                    replace = false,
                    merge = false,
                },
                mini = {
                    timeout = 5000,
                    position = {
                        row = 0,
                        col = -1,
                    },
                },
                split = {
                    size = "30%",
                },
            },
            routes = {
                {
                    filter = {
                        any = {
                            --FIXME: broken after `z=` with `which-key` enabled
                            {
                                event = "msg_show",
                                kind = "", -- this contains `nmap`, `autocmd`
                                -- Use cmd("last") and cmd("history") to check blocked msg
                                -- See also: https://github.com/folke/noice.nvim/issues/259
                            },
                        },
                    },
                    opts = { skip = true },
                },
                {
                    filter = {
                        event = "msg_show",
                        kind = "wmsg",
                        find = "^search hit",
                    },
                    opts = { skip = true },
                },
                {
                    filter = {
                        event = "notify",
                        kind = "info",
                        find = "^" .. require("utils.string").pattern_quote("[LSP] Format request failed, no matching"),
                    },
                    opts = { skip = true },
                },
            },
            lsp = {
                override = {
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                    ["vim.lsp.util.stylize_markdown"] = true,
                    ["cmp.entry.get_documentation"] = true,
                },
                progress = { enabled = false },
                hover = {
                    enabled = false,
                },
                signature = {
                    enabled = false,
                },
                message = {
                    enabled = false,
                },
            },
            presets = {
                -- bottom_search = true,
                lsp_doc_border = true,
                command_palette = true,
                long_message_to_split = true,
            },
        },
        config = function(_, opts)
            require("noice").setup(opts)
            vim.keymap.set({ "c" }, "<S-Enter>", function()
                require("noice").redirect(vim.fn.getcmdline())
            end, { desc = "Redirect Cmdline" })
            vim.keymap.set("n", "<leader>hl", function()
                require("noice").cmd("last")
            end)
            vim.keymap.set("n", "<leader>hh", function()
                require("noice").cmd("history")
            end)
        end,
    },
    {
        "stevearc/dressing.nvim", -- for mason language filter
        event = "VeryLazy",
    },
}
