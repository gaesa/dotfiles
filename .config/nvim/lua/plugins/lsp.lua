return {
    {
        "VonHeikemen/lsp-zero.nvim",
        event = "VeryLazy",
        branch = "v2.x",
        dependencies = {
            { -- LSP Support
                "neovim/nvim-lspconfig",
                dependencies = {
                    { -- Symbols outline & context
                        "SmiteshP/nvim-navbuddy",
                        dependencies = {
                            "SmiteshP/nvim-navic",
                            "MunifTanjim/nui.nvim",
                        },
                        config = function()
                            require("nvim-navbuddy").setup({ lsp = { auto_attach = true } })
                            vim.keymap.set({ "n" }, "<leader>o", function()
                                require("nvim-navbuddy").open()
                                --local function sleep(sec)
                                --    sec = tostring(sec)
                                --    vim.fn.system({ "sleep", sec })
                                --end
                                --sleep(5)
                                --local winid = vim.fn.win_getid() --vim.fn.winnr("$")
                                --print(winid)
                                --vim.api.nvim_set_option_value("winblend", 10, { scope = "local", win = winid })
                            end)
                        end,
                    },
                },
            },
            {
                "williamboman/mason.nvim",
                build = function()
                    ---@diagnostic disable-next-line: param-type-mismatch
                    pcall(vim.cmd, "MasonUpdate")
                end,
                cmd = {
                    "MasonInstall",
                    "MasonUninstall",
                    "Mason",
                    "MasonUninstallAll",
                    "MasonLog",
                },
                dependencies = { "williamboman/mason-lspconfig.nvim" },
            },

            -- Autocompletion
            {
                "hrsh7th/nvim-cmp",
                dependencies = {
                    "hrsh7th/cmp-nvim-lsp",
                    "hrsh7th/cmp-buffer",
                    "hrsh7th/cmp-path",
                    "hrsh7th/cmp-nvim-lua",
                    "saadparwaiz1/cmp_luasnip",
                    {
                        "L3MON4D3/LuaSnip",
                        dependencies = {
                            "rafamadriz/friendly-snippets",
                        },
                        config = function()
                            local ls = require("luasnip")
                            local s = ls.snippet
                            local t = ls.text_node
                            -- local sn = ls.snippet_node
                            -- local i = ls.insert_node
                            -- local f = ls.function_node
                            -- local c = ls.choice_node
                            -- local d = ls.dynamic_node

                            ls.add_snippets("all", {
                                s("hi", {
                                    t("Hello, world!"),
                                }),
                                s({ name = "Shebang for Python", trig = "sbpy", dscr = "Put shebang for Python" }, {
                                    t([[#!/usr/bin/env python3]]),
                                }),
                            })

                            ls.add_snippets("sh", {
                                s(
                                    { name = "Better bash", trig = "set", dscr = "Fail fast and be aware of exit codes" },
                                    {
                                        t([[set -Eeuo pipefail]]),
                                    }
                                ),
                            })

                            ls.add_snippets("c", {
                                s({ name = "Shebang for C", trig = "sbc", dscr = "Put Clang shebang for C" }, {
                                    t([[//usr/bin/clang "$0" -o "${o=$(mktemp)}" && "${o}" "$@" && rm "${o}" && exit]]),
                                }),
                            })
                        end,
                    },
                },
            },
        },
    },
    {
        -- Linter and formatter
        { "jay-babu/mason-null-ls.nvim" },
        { "nvimtools/none-ls.nvim" },
    },
}
