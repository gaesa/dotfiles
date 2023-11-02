local api = vim.api
local autocmd = api.nvim_create_autocmd
local del_autocmd = api.nvim_del_autocmd
local group = api.nvim_create_augroup("config", { clear = true })

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
    pattern = { "xml", "json", "yaml", "html", "css" },
    callback = function()
        vim.bo.tabstop = 2
        vim.bo.shiftwidth = 2
    end,
    group = group,
})

-- HACK: sync visual selection to primary clipboard
-- Limitation: not as elegant as post-hook, not powerful as `post-command-hook` in emacs,
-- and the performace is still not good
-- Issue1: https://github.com/neovim/neovim/issues/4773
-- Issue2: https://github.com/neovim/neovim/issues/19708
-- Pull1: https://github.com/neovim/neovim/pull/13896
-- Pull2: https://github.com/neovim/neovim/pull/3708
-- Post1: https://vi.stackexchange.com/questions/36692/vimscript-how-to-detect-selection-of-a-text-object-in-visual-mode
-- Post2: https://vi.stackexchange.com/questions/31420/how-to-get-the-range-of-selected-lines-in-visual-lines-mode
local sync_selection_timer = vim.loop.new_timer()
local sync_selection_timer_enabled = false
local function sync_selection_callback()
    local function get_start_end(pos1, pos2)
        local pos1_row, pos1_col, pos2_row, pos2_col = pos1[1], pos1[2], pos2[1], pos2[2]

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
end
if vim.fn.getenv("WAYLAND_DISPLAY") ~= vim.NIL then
    autocmd({ "ModeChanged" }, {
        callback = function()
            local mode = string.sub(vim.api.nvim_get_mode().mode, 1, 1)
            if mode == "v" then
                if not sync_selection_timer_enabled then
                    sync_selection_timer:start(0, 500, vim.schedule_wrap(sync_selection_callback))
                    sync_selection_timer_enabled = true
                else
                    return
                end
            else
                if sync_selection_timer_enabled then
                    sync_selection_timer:stop()
                    sync_selection_timer_enabled = false
                else
                    return
                end
            end
        end,
        group = group,
    })
else
end

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
        if not vim.o.nu then
            vim.o.nu = true
        else
            return
        end
    end,
    group = group,
})

-- Improve responsiveness in compact files
autocmd({ "BufRead" }, {
    callback = function(args)
        local function detect_compact_file()
            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            return #lines == 1 and #lines[1] > 200
        end
        -- local function make_plugin_stop(plugin, stop)
        --     return function()
        --         if not package.loaded[plugin] then
        --             return
        --         else
        --             stop()
        --         end
        --     end
        -- end
        -- local stop_treesitter = make_plugin_stop("nvim-treesitter", vim.treesitter.stop)
        -- local stop_illuminate = make_plugin_stop("nvim-treesitter", function()
        --     require("illuminate").pause_buf()
        -- end)
        local function stop_lsp(buf)
            vim.api.nvim_create_autocmd({ "LspAttach" }, {
                buffer = buf,
                ---@diagnostic disable-next-line: redefined-local
                callback = function(args)
                    vim.schedule(function()
                        vim.lsp.buf_detach_client(buf, args.data.client_id)
                    end)
                end,
            })
        end
        local function set_opts()
            local function stop_paren()
                if vim.fn.exists(":DoMatchParen") ~= 2 then
                    return
                else
                    vim.cmd("NoMatchParen")
                end
            end
            vim.opt_local.filetype = "" --core part
            stop_paren()
        end
        if detect_compact_file() then
            set_opts()
            stop_lsp(args.buf)
        else
            return
        end
    end,
})

-- Remove all trailing whitespace
autocmd({ "BufWritePre" }, {
    callback = function()
        local config = vim.b.editorconfig
        if config ~= nil and config["trim_trailing_whitespace"] == "false" then
            return
        else
            vim.cmd([[silent! %s/\s\+$//e]])
        end
    end,
    group = group,
})

-- Retab
autocmd({ "BufWritePre" }, {
    callback = function()
        local config = vim.b.editorconfig
        if config ~= nil and config["indent_style"] == "tab" then
            return
        else
            vim.cmd.retab({ bang = true })
        end
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

-- Track default value of `vim.bo.spellcapcheck`
autocmd({ "BufEnter" }, {
    callback = function()
        vim.b.spellcapcheck = vim.bo.spellcapcheck
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
