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

    { "theprimeagen/harpoon" },

    { "mbbill/undotree", cmd = { "UndotreeToggle" } },

    --  'tpope/vim-fugitive',

    {
        "VonHeikemen/lsp-zero.nvim",
        branch = "v1.x",
        dependencies = {
            -- LSP Support
            { "neovim/nvim-lspconfig" },
            {
                "williamboman/mason.nvim",
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
                },
            },

            -- Snippets
            {
                "L3MON4D3/LuaSnip",
                dependencies = {
                    "rafamadriz/friendly-snippets",
                },
                keys = {
                    {
                        "<tab>",
                        function()
                            return require("luasnip").jumpable(1) and "<Plug>luasnip-jump-next" or "<tab>"
                        end,
                        expr = true,
                        silent = true,
                        mode = "i",
                    },
                    {
                        "<tab>",
                        function()
                            require("luasnip").jump(1)
                        end,
                        mode = "s",
                    },
                    {
                        "<s-tab>",
                        function()
                            require("luasnip").jump(-1)
                        end,
                        mode = { "i", "s" },
                    },
                },
            },
        },
    },

    -- Linter and formatter
    { "jose-elias-alvarez/null-ls.nvim" },
    { "jay-babu/mason-null-ls.nvim" },

    -- Motion
    {
        "phaazon/hop.nvim",
        branch = "v2", -- optional but strongly recommended
    },

    -- Editing support
    {
        "windwp/nvim-autopairs",
        event = "VeryLazy",
        config = true,
    },

    { "lukas-reineke/indent-blankline.nvim", event = "VeryLazy" },

    -- Input method
    { "h-hg/fcitx.nvim", event = "VeryLazy" },
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
