local actions = require("telescope.actions")
require("telescope").setup({
    defaults = {
        layout_config = {
            prompt_position = "top",
        },
        sorting_strategy = "ascending",

        -- These lines doesn't work
        -- file_ignore_patterns = {
        --     ".git",
        --     "*.local/share/*",
        --     "*.local/state/*",
        --     "*.local/var",
        --     ".cache",
        --     ".var",
        --     "*.pdf",
        --     "*.mkv",
        --     "*.mp4",
        --     "*.zip",
        --     "*.png",
        --     "*.jpg",
        --     "*.jpeg",
        -- },

        -- path_display = { "smart" },
        mappings = {
            i = {
                -- ["<esc>"] = actions.close,
                ["<M-k>"] = actions.move_selection_previous,
                ["<M-j>"] = actions.move_selection_next,
                ["<C-u>"] = false,
            },
            n = {
                ["<M-k>"] = actions.move_selection_previous,
                ["<M-j>"] = actions.move_selection_next,
            },
        },
    },
    -- pickers = {
    --      find_files = {
    --          find_command = { "rg", "--files", "--hidden", "-g", "!.git" },
    --          -- find_command = {
    --          --     "fd",
    --          --     "--type",
    --          --     "f",
    --          --     "--color=never",
    --          --     "--hidden",
    --          --     "--follow",
    --          --     "-E",
    --          --     ".git/*",
    --          -- },
    --          -- layout_config = {
    --          --     height = 0.70,
    --          -- },
    --      },
    --     buffers = {
    --         show_all_buffers = true,
    --     },
    -- },
})

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
vim.keymap.set("n", "<leader>fp", builtin.git_files, {})
vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})

vim.keymap.set("n", "<leader>fs", function()
    builtin.grep_string({ search = vim.fn.input("Grep > ") })
end)

-- To get fzf loaded and working with telescope, you need to call
-- load_extension, somewhere after setup function:
require("telescope").load_extension("fzf")
