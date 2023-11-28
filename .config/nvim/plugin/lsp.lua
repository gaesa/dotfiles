if vim.g.vscode then
    return
end
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

lsp.on_attach(function(_, bufnr) --client
    lsp.default_keymaps({ buffer = bufnr })
    local opts = { buffer = bufnr }
    local map = vim.keymap.set

    map("n", "<leader>r", vim.lsp.buf.rename, opts)
end)

lsp.set_sign_icons({
    error = "E",
    warn = "W",
    hint = "H",
    info = "I",
})

-- warning: multiple different client offset_encodings
-- detected for buffer, this is not supported yet
-- https://github.com/jose-elias-alvarez/null-ls.nvim/issues/428
-- https://github.com/VonHeikemen/lsp-zero.nvim/blob/v2.x/doc/md/api-reference.md#configurename-opts
lsp.configure("clangd", {
    capabilities = { "utf-16" },
})

lsp.setup()

-- Completion
-- Make sure you setup `cmp` after lsp-zero
local cmp = require("cmp")
local cmp_action = require("lsp-zero").cmp_action()
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
        ["<C-c>"] = cmp.mapping.abort(),
        ["<C-g>"] = cmp.mapping.abort(),

        ["<Tab>"] = cmp_action.tab_complete(),
        ["<S-Tab>"] = cmp_action.select_prev_or_fallback(),

        ["<C-n>"] = cmp_action.luasnip_next_or_expand(),
        ["<C-p>"] = cmp_action.luasnip_jump_backward(),
    },
})

-- Formatter and linter
-- See mason-null-ls.nvim's documentation for more details:
-- https://github.com/jay-babu/mason-null-ls.nvim#setup
local null_ls = require("null-ls")
require("mason-null-ls").setup({
    ensure_installed = { "stylua" },
    automatic_installation = false,
    automatic_setup = true,
    handlers = {
        ruff = function(_, _) --source_name, methods
            null_ls.register(null_ls.builtins.diagnostics.ruff)
        end,

        clang_format = function(_, _) --source_name, methods
            null_ls.register(null_ls.builtins.formatting.clang_format.with({
                extra_args = { "-style={IndentWidth: 4, ObjCBlockIndentWidth: 4, CommentPragmas: '^[^ ]',}" },
            }))
        end,

        prettier = function(_, _)
            null_ls.register(null_ls.builtins.formatting.prettier.with({
                extra_args = function(params)
                    local config = vim.b.editorconfig
                    if vim.bo.filetype == "markdown" or (config ~= nil and config["indent_size"] ~= nil) then
                        return {}
                    else
                        return {
                            "--tab-width",
                            vim.api.nvim_buf_get_option(params.bufnr, "shiftwidth"),
                        }
                    end
                end,
            }))
        end,

        stylua = function(_, _)
            null_ls.register(null_ls.builtins.formatting.stylua.with({
                extra_args = function(_)
                    local config = vim.b.editorconfig
                    if config ~= nil and config["indent_style"] ~= nil then
                        return {}
                    else
                        return {
                            "--indent-type",
                            "Spaces",
                        }
                    end
                end,
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
