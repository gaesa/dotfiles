-- Learn the keybindings, see :help lsp-zero-keybindings
-- Learn to configure LSP servers, see :help lsp-zero-api-showcase
local lsp = require("lsp-zero").preset({
    float_border = "rounded",
    call_servers = "local",
    configure_diagnostics = true,
    setup_servers_on_start = true,
    set_lsp_keymaps = {
        preserve_mappings = false,
        omit = {},
    },
    manage_nvim_cmp = {
        set_sources = false,
        set_basic_mappings = false,
        set_extra_mappings = false,
        use_luasnip = true,
        set_format = true,
        documentation_window = true,
    },
})

-- (Optional) Configure lua language server for neovim
require("lspconfig").lua_ls.setup(lsp.nvim_lua_ls())

lsp.ensure_installed({
    "lua_ls",
})

lsp.on_attach(function(client, bufnr)
    lsp.default_keymaps({ buffer = bufnr })
    local opts = { buffer = bufnr }
    local map = vim.keymap.set

    map("n", "<leader>r", "<cmd>lua vim.lsp.buf.rename()<cr>", opts)
end)

lsp.set_sign_icons({
    error = "E",
    warn = "W",
    hint = "H",
    info = "I",
})

lsp.setup()

-- cmp
-- Make sure you setup `cmp` after lsp-zero
local cmp = require("cmp")
local cmp_action = require("lsp-zero").cmp_action()
local cmp_select_opts = { behavior = cmp.SelectBehavior.Select }
require("luasnip.loaders.from_vscode").lazy_load()

cmp.setup({
    preselect = "item",
    completion = {
        completeopt = "menu,menuone,noinsert",
    },
    window = {
        -- completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
    },
    sources = {
        { name = "nvim_lsp" },
        { name = "nvim_lua" },
        { name = "luasnip", keyword_length = 2 },
        { name = "path" },
        { name = "buffer", keyword_length = 3 },
    },
    mapping = {
        -- `Enter` key to confirm completion
        ["<CR>"] = cmp.mapping.confirm({ select = true }),

        ["<Up>"] = cmp.mapping.select_prev_item(cmp_select_opts),
        ["<Down>"] = cmp.mapping.select_next_item(cmp_select_opts),

        ["<Tab>"] = cmp_action.tab_complete(),
        ["<S-Tab>"] = cmp_action.select_prev_or_fallback(),

        --["<Esc>"] = cmp.mapping.abort(),
    },
})

-- See mason-null-ls.nvim's documentation for more details:
-- https://github.com/jay-babu/mason-null-ls.nvim#setup
local null_ls = require("null-ls")
require("mason-null-ls").setup({
    ensure_installed = { "stylua" },
    automatic_installation = false,
    automatic_setup = true,
    handlers = {
        ruff = function(source_name, methods)
            null_ls.register(null_ls.builtins.diagnostics.ruff)
        end,

        clang_format = function(source_name, methods)
            null_ls.register(null_ls.builtins.formatting.clang_format.with({
                extra_args = { "-style={IndentWidth: 4, ObjCBlockIndentWidth: 4, CommentPragmas: '^[^ ]',}" },
            }))
        end,
    },
})

-- Integrate null-ls with lsp-zero
-- https://github.com/VonHeikemen/lsp-zero.nvim/blob/v1.x/advance-usage.md
-- https://github.com/VonHeikemen/lsp-zero.nvim/blob/v2.x/doc/md/guides/integrate-with-null-ls.md
null_ls.setup({
    on_attach = function(client, bufnr)
        -- Formatting manually
        local format_cmd = function(input)
            vim.lsp.buf.format({
                id = client.id,
                timeout_ms = 5000,
                async = input.bang,
            })
        end
        local bufcmd = vim.api.nvim_buf_create_user_command
        bufcmd(bufnr, "NullFormat", format_cmd, {
            bang = false,
            range = true,
            desc = "Format using null-ls",
        })
        -- Default `F3` from lsp-zero doesn't support range formatting
        vim.keymap.set({ "n", "x" }, "gq", ":NullFormat<CR>", { noremap = true })
    end,

    sources = {
        -- You can add tools not supported by mason.nvim
    },
})
