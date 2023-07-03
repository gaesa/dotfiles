-- Bootstrap
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- Plugins
local plugins = {
    {
        "nvim-telescope/telescope.nvim",
        tag = "0.1.1",
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
    },
    { "nanotee/zoxide.vim", cmd = { "Z", "Zi" } },

    {
        "sainnhe/everforest",
        --priority = 1000, -- make sure to load this before all the other start plugins
    },
    --  'neanias/everforest-nvim'
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { event = "VeryLazy", "kyazdani42/nvim-web-devicons" },
    },

    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        event = "VeryLazy",
        cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
    },

    { "theprimeagen/harpoon", event = "VeryLazy" },
    {
        "mbbill/undotree",
        event = { "TextChanged", "TextChangedI" },
        cmd = { "UndotreeFocus", "UndotreeToggle", "UndotreeShow", "UndotreeHide" },
    },

    --  'tpope/vim-fugitive',

    {
        "VonHeikemen/lsp-zero.nvim",
        branch = "v2.x",
        event = "VeryLazy",
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
                event = "InsertEnter",
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
                    },
                },
            },
        },
    },

    -- Highlight all uses of the symbol under the cursor
    { "RRethy/vim-illuminate", event = "VeryLazy" },

    -- Linter and formatter
    { "jay-babu/mason-null-ls.nvim", event = "VeryLazy" },
    { "jose-elias-alvarez/null-ls.nvim", event = "VeryLazy" },

    -- Commment
    { "numToStr/Comment.nvim", config = true, event = "VeryLazy" },

    -- Motion
    {
        "echasnovski/mini.jump",
        version = false,
        event = "VeryLazy",
    },

    -- Editing support
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = true,
    },
    {
        "windwp/nvim-ts-autotag",
        event = "InsertEnter",
    },
    {
        "echasnovski/mini.surround",
        version = false,
        event = "VeryLazy",
        config = true,
    },

    { "lukas-reineke/indent-blankline.nvim", event = "VeryLazy" },

    -- Input method
    { "h-hg/fcitx.nvim", event = "InsertEnter" },
}

local opts = {
    defaults = { lazy = true },
    checker = { enable = true, frequency = 604800 },
    performance = {
        cache = {
            enabled = true,
        },
        reset_packpath = true, -- reset the package path to improve startup time
    },
}

require("lazy").setup(plugins, opts)
