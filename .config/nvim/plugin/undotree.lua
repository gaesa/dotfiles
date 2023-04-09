vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)
-- stylua: ignore
vim.api.nvim_exec2([[
    if has("persistent_undo")
       let target_path = expand('~/.local/state/undo')

        " create the directory and any parent directories
        " if the location does not exist.
        if !isdirectory(target_path)
            call mkdir(target_path, "p", 0700)
        endif

        let &undodir=target_path
        set undofile
    endif

    if !exists('g:undotree_SplitWidth')
        let g:undotree_SplitWidth = 5
    endif]],
    { output = false }
)
