local autocmd = vim.api.nvim_create_autocmd
local del_autocmd = vim.api.nvim_del_autocmd
local group = vim.api.nvim_create_augroup("default.conf", { clear = true })

-- Toggle absolute and relative numbering by insert/normal mode
autocmd({ "InsertEnter" }, { command = [[set nornu]], group = group })
autocmd({ "InsertLeave" }, { command = [[set rnu]], group = group })

-- Change indent for some filetypes
autocmd({ "FileType" }, {
    pattern = { "xml", "html", "javascript" },
    callback = function()
        vim.opt.tabstop = 2
        vim.opt.shiftwidth = 2
    end,
    group = group,
})

-- Yank selection to primary clipboard automatically
-- limitation: in some cases, this autocmd doesn't work, for example,
-- when the cursor is at the end of a word, after pressing `viw`, only the last character is yanked
-- related pull: https://github.com/neovim/neovim/pull/13896#issuecomment-774680224
-- related post: https://vi.stackexchange.com/questions/36692/vimscript-how-to-detect-selection-of-a-text-object-in-visual-mode
autocmd({ "CursorMoved", "ModeChanged" }, {
    pattern = "*",
    callback = function()
        local mode = string.sub(vim.api.nvim_get_mode().mode, 1, 1)
        if mode ~= "v" and mode ~= "V" then
            return
        else
            vim.cmd([[normal! "*y]])
            vim.cmd([[normal! gv]])
        end
    end,
    group = group,
})

-- Return to last edited postition
autocmd(
    { "BufReadPost" },
    { command = [[if line("'\"") > 1 && line("'\"") <= line("$") | execute "normal! g`\"" | endif]], group = group }
)
autocmd({ "FileType" }, { pattern = { "gitcommit", "gitrebase" }, command = [[normal! gg0]], group = group })
autocmd({ "BufWinEnter" }, { command = [[normal! zz]], group = group })

-- Remove all trailing whitespace
autocmd({ "BufWritePre" }, { pattern = { "*" }, command = [[silent! %s/\s\+$//e]], group = group })

-- Retab
autocmd({ "BufWritePre" }, { pattern = { "*" }, command = [[silent! %retab]], group = group })

-- Automatically enable spell checking in specific files
autocmd({ "FileType" }, { pattern = { "markdown", "gitcommit" }, command = [[set spell]], group = group })

-- Automatically change shortcuts in specific files
autocmd({ "FileType" }, {
    pattern = "gitcommit",
    callback = function()
        vim.keymap.set({ "n", "i" }, "<C-q>", "<ESC>:cq<CR>", { noremap = true })
        vim.keymap.set("n", "Q", "<ESC>:cq<CR>", { silent = true })
    end,
    group = group,
})

-- Highlight yanked text
autocmd({ "TextYankPost" }, {
    pattern = "*",
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

-- Quit with 'q'
autocmd({ "FileType" }, {
    pattern = { "help", "man", "startuptime", "qf" },
    command = [[nnoremap <buffer><silent> q :quit<CR>]],
    group = group,
})
