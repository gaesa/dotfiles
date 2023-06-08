vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)

if vim.fn.has("persistent_undo") == 1 then
    -- create the directory and any parent directories
    -- if the location does not exist.
    local target_path = vim.opt.undodir._value
    if vim.fn.isdirectory(target_path) == 0 then
        vim.fn.mkdir(target_path, "p", 0700)
    end

    vim.g.undotree_SplitWidth = 5
    vim.g.undotree_DiffpanelHeight = 14
    vim.g.undotree_DiffCommand = "git diff --no-index"
end
