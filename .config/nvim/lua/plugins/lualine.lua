-- Mixed indent status
local function mixindent()
    local space_pat = [[\v^ +]]
    local tab_pat = [[\v^\t+]]
    local space_indent = vim.fn.search(space_pat, "nwc")
    local tab_indent = vim.fn.search(tab_pat, "nwc")
    local mixed = (space_indent > 0 and tab_indent > 0)
    local mixed_same_line
    if not mixed then
        mixed_same_line = vim.fn.search([[\v^(\t+ | +\t)]], "nwc")
        mixed = mixed_same_line > 0
    end
    if vim.bo.filetype == "help" then
        return ""
    elseif not mixed then
        return ""
    elseif mixed_same_line ~= nil and mixed_same_line > 0 then
        return "mixed-indent:" .. mixed_same_line
    end
    local space_indent_cnt = vim.fn.searchcount({ pattern = space_pat, max_count = 1e3 }).total
    local tab_indent_cnt = vim.fn.searchcount({ pattern = tab_pat, max_count = 1e3 }).total
    if space_indent_cnt > tab_indent_cnt then
        return "mix-indent:" .. tab_indent
    else
        return "mix-indent:" .. space_indent
    end
end

-- Override 'encoding': Display only when encoding isn't UTF-8
local function encoding()
    if vim.bo.fenc == "utf-8" then
        return ""
    else
        return vim.bo.fenc
    end
end

return {
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "kyazdani42/nvim-web-devicons" },
        event = "VeryLazy",
        opts = {
            options = {
                icons_enabled = true,
                theme = "auto",
                component_separators = { left = "", right = "" },
                section_separators = { left = "", right = "" },
                disabled_filetypes = {
                    statusline = {},
                    winbar = {},
                },
                ignore_focus = {},
                always_divide_middle = true,
                globalstatus = false,
                refresh = {
                    statusline = 350,
                    tabline = 1000,
                    winbar = 1000,
                },
            },
            sections = {
                lualine_a = { "mode" },
                lualine_b = {
                    "branch",
                    "diff",
                    {
                        "diagnostics",
                        sources = { "nvim_diagnostic" },
                        symbols = { error = " ", warn = " ", info = " ", hint = " " },
                    },
                },
                lualine_c = {
                    { "filename", file_status = true, path = 1 },
                    {
                        function()
                            return require("noice").api.statusline.mode.get()
                        end,
                        cond = function()
                            return require("noice").api.statusline.mode.has()
                                and (
                                    not vim.startswith(
                                        require("noice").api.statusline.mode.get(),
                                        "-- " --exclude cursor state
                                    )
                                )
                        end,
                        color = { fg = "#ff9e64" },
                    },
                    -- {-- can't be easily overwritten
                    --     function()
                    --         return require("noice").api.status.message.get_hl()
                    --     end,
                    --     cond = function()
                    --         if not require("noice").api.status.message.has() then
                    --             return false
                    --         else
                    --             local info = require("noice").api.status.message.get_hl()
                    --             return vim.startswith(info, "%#NoiceAttr79#") --emsg
                    --         end
                    --     end,
                    -- },
                },
                lualine_x = {
                    {
                        function()
                            require("lazy.status").updates()
                        end,
                        cond = function()
                            require("lazy.status").has_updates()
                        end,
                        color = { fg = "#ff9e64" },
                    },
                    encoding,
                    {
                        "fileformat",
                        symbols = {
                            unix = "",
                            dos = "CRLF",
                            mac = "CR",
                        },
                    },
                    { "filetype", icons_enabled = false },
                },
                lualine_y = {
                    {
                        mixindent,
                        color = "WarningMsg",
                    },
                    "progress",
                },
                lualine_z = { "location" },
            },
            inactive_sections = {
                lualine_a = { "mode" },
                lualine_b = {},
                lualine_c = { "filename" },
                lualine_x = { "progress" },
                lualine_y = { "location" },
                lualine_z = {},
            },
            tabline = {},
            winbar = {},
            inactive_winbar = {},
            extensions = {},
        },
    },
}
