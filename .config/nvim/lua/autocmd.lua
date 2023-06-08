local autocmd = vim.api.nvim_create_autocmd
local del_autocmd = vim.api.nvim_del_autocmd
local group = vim.api.nvim_create_augroup("default.conf", { clear = true })

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
    pattern = { "xml", "html", "javascript" },
    callback = function()
        vim.bo.tabstop = 2
        vim.bo.shiftwidth = 2
    end,
    group = group,
})

-- Yank selection to primary clipboard automatically
-- limitation: in some cases, this autocmd doesn't work, for example,
-- when the cursor is at the end of a word, after pressing `viw`, only the last character is yanked
-- related pull: https://github.com/neovim/neovim/pull/13896#issuecomment-774680224
-- related post: https://vi.stackexchange.com/questions/36692/vimscript-how-to-detect-selection-of-a-text-object-in-visual-mode
autocmd({ "CursorMoved", "ModeChanged" }, {
    callback = function()
        local mode = string.sub(vim.api.nvim_get_mode().mode, 1, 1)
        if mode == "v" or mode == "V" then
            vim.cmd.normal({ args = { '"*y' }, bang = true })
            vim.cmd.normal({ args = { "gv" }, bang = true })
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

-- Remove all trailing whitespace
autocmd({ "BufWritePre" }, {
    command = [[silent! %s/\s\+$//e]],
    group = group,
})

-- Formatter
-- Should be placed before 'Retab' as some formatters don't support space indent
autocmd({ "BufWritePre" }, {
    callback = function()
        vim.lsp.buf.format({ async = false })
    end,
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
autocmd({ "FileType" }, {
    pattern = "gitcommit",
    callback = function()
        vim.keymap.set({ "n", "i" }, "<C-q>", "<ESC>:cq<CR>", { buffer = true, noremap = true, silent = true })
        vim.keymap.set({ "n" }, "Q", ":cq<CR>", { buffer = true, noremap = true, silent = true })
    end,
    group = group,
})

-- Quit with 'q'
autocmd({ "FileType" }, {
    pattern = { "help", "man", "startuptime", "qf" },
    callback = function()
        vim.keymap.set({ "n" }, "q", ":q<CR>", { buffer = true, noremap = true, silent = true })
    end,
    group = group,
})
