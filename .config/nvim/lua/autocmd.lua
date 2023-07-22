local api = vim.api
local autocmd = api.nvim_create_autocmd
local del_autocmd = api.nvim_del_autocmd
local group = api.nvim_create_augroup("default.conf", { clear = true })

-- Toggle absolute and relative numbering by insert/normal mode
autocmd({ "InsertEnter" }, {
    callback = function()
        vim.wo.rnu = false
    end,
    group = group,
})
autocmd({ "InsertLeave" }, {
    callback = function()
        vim.wo.rnu = true
    end,
    group = group,
})

-- Change indent for some filetypes
autocmd({ "FileType" }, {
    pattern = { "xml", "json", "yaml", "html", "css", "javascript" },
    callback = function()
        vim.bo.tabstop = 2
        vim.bo.shiftwidth = 2
    end,
    group = group,
})

-- Sync visual selection to primary clipboard
-- Limitation: In certain cases, the above autocmd may not work.
-- For instance, when the cursor is positioned at the end of a word and
-- the command `viw` is executed, only the last character is yanked.
-- Because the cursor's position is the same as the start of the visual selection.
-- One method is to use `gv` and the `<` and `>` marks,
-- but this approach can potentially lead to infinite recursion and has a performance problem.
-- Additionally this method is not considered elegant.
-- Issue1: https://github.com/neovim/neovim/issues/4773
-- Issue2: https://github.com/neovim/neovim/issues/19708
-- Pull1: https://github.com/neovim/neovim/pull/13896
-- Pull2: https://github.com/neovim/neovim/pull/3708
-- Post1: https://vi.stackexchange.com/questions/36692/vimscript-how-to-detect-selection-of-a-text-object-in-visual-mode
-- Post2: https://vi.stackexchange.com/questions/31420/how-to-get-the-range-of-selected-lines-in-visual-lines-mode
autocmd({ "CursorMoved", "ModeChanged" }, {
    callback = function()
        local function get_start_end(pos1, pos2)
            local pos1_row = pos1[1]
            local pos1_col = pos1[2]
            local pos2_row = pos2[1]
            local pos2_col = pos2[2]

            if pos1_row < pos2_row then
                return pos1, pos2
            elseif pos1_row == pos2_row then
                if pos1_col < pos2_col then
                    return pos1, pos2
                else
                    return pos2, pos1
                end
            else
                return pos2, pos1
            end
        end
        local mode = string.sub(vim.api.nvim_get_mode().mode, 1, 1)
        if mode == "v" then
            -- I have tested that vim.api.nvim_buf_get_mark(0, "v") doesn't
            -- retrieve the correct position when compared to vim.fn.getpos("v").
            -- Both `vim.fn.getpos("'<")` and `vim.api.nvim_buf_get_mark(0, "<")` fail to
            -- retrieve the latest content when the current mode is visual mode.
            local v_pos = vim.fn.getpos("v")
            v_pos = { v_pos[2], v_pos[3] - 1 } -- (1, 1)-index to (1, 0)-index
            local cur_pos = api.nvim_win_get_cursor(0)
            local start_pos, end_pos = get_start_end(v_pos, cur_pos)
            local text = api.nvim_buf_get_text(0, start_pos[1] - 1, start_pos[2], end_pos[1] - 1, end_pos[2] + 1, {})
            vim.fn.setreg("*", text)
        else
            return
        end
    end,
    group = group,
})

-- Return to last edited postition and `zz`
-- checks if the '" mark is defined, and jumps to it if so
-- limitation: doesn't work for `help`
autocmd({ "BufWinEnter" }, {
    callback = function()
        local excluded_filetype = { gitcommit = true, gitrebase = true }
        if excluded_filetype[vim.bo.filetype] then
            vim.cmd.normal({ args = { "zz" }, bang = true })
        elseif vim.fn.line([['"]]) > 1 and (vim.fn.line([['"]]) <= vim.fn.line("$")) then
            vim.cmd.normal({ args = { [[g`"]] }, bang = true })
            vim.cmd.normal({ args = { "zz" }, bang = true })
        else
            vim.cmd.normal({ args = { "zz" }, bang = true })
        end
    end,
    group = group,
})
autocmd({ "filetype" }, {
    pattern = { "help" },
    callback = function()
        vim.keymap.set({ "n", "x" }, "j", "gj", { buffer = true, silent = true })
        vim.keymap.set({ "n", "x" }, "k", "gk", { buffer = true, silent = true })
    end,
    group = group,
})

-- Remove all trailing whitespace
autocmd({ "BufWritePre" }, {
    command = [[silent! %s/\s\+$//e]],
    group = group,
})

-- Retab
autocmd({ "BufWritePre" }, {
    callback = function()
        vim.cmd.retab({ bang = true })
    end,
    group = group,
})

-- Automatically enable spell checking in specific files
autocmd({ "FileType" }, {
    pattern = { "markdown", "gitcommit" },
    callback = function()
        vim.wo.spell = true
    end,
    group = group,
})

-- Highlight yanked text
autocmd({ "TextYankPost" }, {
    callback = function()
        vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
    end,
    group = group,
})

-- Auto remove search highlight and rehighlight when using n or N
-- https://github.com/glepnir/hlsearch.nvim
local function stop_hl()
    if vim.v.hlsearch ~= 0 then
        local keycode = vim.api.nvim_replace_termcodes("<Cmd>nohl<CR>", true, false, true)
        vim.api.nvim_feedkeys(keycode, "n", false)
    else
        return
    end
end
local function start_hl()
    local res = vim.fn.getreg("/")
    if vim.v.hlsearch == 1 and vim.fn.search([[\%#\zs]] .. res, "cnW") == 0 then
        stop_hl()
    else
        return
    end
end

local buffers = {}
local function hs_event(bufnr)
    if buffers[bufnr] then
        return
    else
        buffers[bufnr] = true
        local cm_id = autocmd("CursorMoved", {
            buffer = bufnr,
            group = group,
            callback = start_hl,
            desc = "Auto hlsearch",
        })

        local ie_id = autocmd("InsertEnter", {
            buffer = bufnr,
            group = group,
            callback = stop_hl,
            desc = "Auto remove hlsearch",
        })

        autocmd("BufDelete", {
            buffer = bufnr,
            group = group,
            callback = function(opt)
                buffers[bufnr] = nil
                pcall(del_autocmd, cm_id)
                pcall(del_autocmd, ie_id)
                pcall(del_autocmd, opt.id)
            end,
        })
    end
end

autocmd("BufWinEnter", {
    group = group,
    callback = function(opt)
        hs_event(opt.buf)
    end,
    desc = "Auto remove search highlight and rehighlight when using n or N",
})

-- Automatically change shortcuts in specific files
autocmd({ "BufEnter" }, {
    -- `WinEnter` doesn't trigger after running `git commit` from shell
    -- `vim.wo` is set after the `BufWinEnter` event is triggered
    callback = function()
        local git_filetype = { gitcommit = true, gitrebase = true }
        if vim.wo.diff or git_filetype[vim.bo.filetype] then
            vim.keymap.set({ "n", "i" }, "<C-q>", "<Esc>:cq<CR>", { buffer = true, silent = true })
            vim.keymap.set({ "n" }, "q", ":cq<CR>", { buffer = true, silent = true })
        else
            return
        end
    end,
    group = group,
})
