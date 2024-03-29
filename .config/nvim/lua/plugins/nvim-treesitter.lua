return {
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
        opts = {
            -- A list of parser names, or "all" (the four listed parsers should always be installed)
            ensure_installed = { "c", "lua", "vim", "vimdoc" },

            -- Install parsers synchronously (only applied to `ensure_installed`)
            sync_install = false,

            -- Automatically install missing parsers when entering buffer
            -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
            auto_install = true,

            highlight = {
                -- `false` will disable the whole extension
                enable = not vim.g.vscode,

                -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
                -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
                -- Using this option may slow down your editor, and you may see some duplicate highlights.
                -- Instead of true it can also be a list of languages
                additional_vim_regex_highlighting = false,
            },
        },
        config = function(_, opts)
            require("nvim-treesitter.configs").setup(opts)

            local function fix_indent()
                local function toggle_indent(value)
                    require("nvim-treesitter.configs").setup({
                        indent = {
                            enable = value,
                        },
                    })
                end
                -- Fix indent for python
                toggle_indent(vim.bo.filetype == "python")
            end
            vim.api.nvim_create_autocmd({ "BufEnter" }, {
                callback = fix_indent,
                group = vim.api.nvim_create_augroup("plugins.nvim-treesitter@fix-indent", {}),
            })
            fix_indent()
        end,
    },
}
