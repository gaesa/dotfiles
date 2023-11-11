return {
    {
        "nvim-telescope/telescope.nvim",
        cond = not vim.g.vscode,
        tag = "0.1.4",
        -- or branch = '0.1.x',
        dependencies = {
            { "nvim-lua/plenary.nvim" },
            {
                "nvim-telescope/telescope-fzf-native.nvim",
                -- Uninstall and then re-install this plugin to fix the problem:
                -- 'fzf' extension doesn't exist or isn't installed
                build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
            },
        },
        event = "VeryLazy",
        config = function()
            local actions = require("telescope.actions")
            require("telescope").setup({
                defaults = {
                    layout_config = {
                        prompt_position = "top",
                    },
                    sorting_strategy = "ascending",
                    mappings = {
                        i = {
                            -- ["<esc>"] = actions.close,
                            ["<C-k>"] = actions.move_selection_previous,
                            ["<C-j>"] = actions.move_selection_next,
                            ["<C-u>"] = false,
                            ["<C-g>"] = actions.close,
                        },
                        n = {
                            ["<C-k>"] = actions.move_selection_previous,
                            ["<C-j>"] = actions.move_selection_next,
                            ["q"] = actions.close,
                            ["<C-c>"] = actions.close,
                            ["<C-g>"] = actions.close,
                        },
                    },
                },
            })

            local builtin = require("telescope.builtin")
            vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
            vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
            vim.keymap.set("n", "<leader>pf", builtin.git_files, {})
            vim.keymap.set("n", "<leader>bf", builtin.buffers, {})
            vim.keymap.set("n", "<C-h>", builtin.help_tags, {})

            -- To get fzf loaded and working with telescope, you need to call
            -- load_extension, somewhere after setup function:
            require("telescope").load_extension("fzf")
        end,
    },
}
