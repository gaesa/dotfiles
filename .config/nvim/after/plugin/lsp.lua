-- Learn the keybindings, see :help lsp-zero-keybindings
-- Learn to configure LSP servers, see :help lsp-zero-api-showcase
local lsp = require("lsp-zero")
lsp.preset("recommended")

-- (Optional) Configure lua language server for neovim
lsp.nvim_workspace()

lsp.ensure_installed({
    "lua_ls",
})

lsp.set_preferences({
    sign_icons = {
        error = "E",
        warn = "W",
        hint = "H",
        info = "I",
    },
})

-- Enable nvim-cmp only on TAB
-- lsp.setup_nvim_cmp({
--     completion = {
--         autocomplete = false,
--     },
-- })

lsp.on_attach(function(client, bufnr)
    local opts = { buffer = bufnr, remap = false }

    vim.keymap.set("n", "gd", function()
        vim.lsp.buf.definition()
    end, opts)

    vim.keymap.set("n", "K", function()
        vim.lsp.buf.hover()
    end, opts)

    vim.keymap.set("n", "<leader>vws", function()
        vim.lsp.buf.workspace_symbol()
    end, opts)

    vim.keymap.set("n", "<leader>vd", function()
        vim.diagnostic.open_float()
    end, opts)

    vim.keymap.set("n", "[d", function()
        vim.diagnostic.goto_next()
    end, opts)

    vim.keymap.set("n", "]d", function()
        vim.diagnostic.goto_prev()
    end, opts)

    vim.keymap.set("n", "<leader>vca", function()
        vim.lsp.buf.code_action()
    end, opts)

    vim.keymap.set("n", "<leader>vrr", function()
        vim.lsp.buf.references()
    end, opts)

    vim.keymap.set("n", "<leader>vrn", function()
        vim.lsp.buf.rename()
    end, opts)

    vim.keymap.set("i", "<C-h>", function()
        vim.lsp.buf.signature_help()
    end, opts)
end)
lsp.setup()

-- Integrate null-ls with lsp-zero
-- null_ls.builtins.formatting.prettier
-- https://github.com/VonHeikemen/lsp-zero.nvim/blob/v1.x/advance-usage.md
local null_ls = require("null-ls")
local null_opts = lsp.build_options("null-ls", {})

null_ls.setup({
    on_attach = function(client, bufnr)
        null_opts.on_attach(client, bufnr)

        local format_cmd = function(input)
            vim.lsp.buf.format({
                id = client.id,
                timeout_ms = 5000,
                async = input.bang,
            })
        end
        local bufcmd = vim.api.nvim_buf_create_user_command
        bufcmd(bufnr, "NullFormat", format_cmd, {
            bang = true,
            range = true,
            desc = "Format using null-ls",
        })
    end,
    sources = {
        null_ls.builtins.formatting.black,
        null_ls.builtins.formatting.shfmt,
        null_ls.builtins.formatting.stylua,
        null_ls.builtins.formatting.prettier,
        null_ls.builtins.formatting.clang_format.with({
            extra_args = { "-style={IndentWidth: 4}" },
        }),
        -- You can add tools not supported by mason.nvim
    },
})

-- See mason-null-ls.nvim's documentation for more details:
-- https://github.com/jay-babu/mason-null-ls.nvim#setup
require("mason-null-ls").setup({
    ensure_installed = nil,
    automatic_installation = false,
    automatic_setup = false,
})
-- Required when `automatic_setup` is true
-- require("mason-null-ls").setup_handlers()

-- Formatting
-- vim.api.nvim_command([[autocmd BufWritePre <buffer> NullFormat]])
vim.keymap.set("n", "<leader>F", ":NullFormat<CR>")

-- Show disgnostic directly
vim.diagnostic.config({
    virtual_text = true,
})
