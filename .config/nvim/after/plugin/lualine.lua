-- Trailing whitespaces status
local function trailing()
    local space = vim.fn.search([[\s\+$]], "nwc")
    return space ~= 0 and "Traling:" .. space or ""
end

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
    if not mixed then
        return ""
    end
    if mixed_same_line ~= nil and mixed_same_line > 0 then
        return "mixed-indent:" .. mixed_same_line
    end
    local space_indent_cnt = vim.fn.searchcount({ pattern = space_pat, max_count = 1e3 }).total
    local tab_indent_cnt = vim.fn.searchcount({ pattern = tab_pat, max_count = 1e3 }).total
    if space_indent_cnt > tab_indent_cnt then
        return "mix-indent-file:" .. tab_indent
    else
        return "mix-indent-file:" .. space_indent
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

-- require("lualine").setup()
require("lualine").setup({
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
            statusline = 1000,
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
        lualine_c = { { "filename", file_status = true, path = 1 } },
        lualine_x = {
            encoding,
            {
                "fileformat",
                symbols = {
                    unix = "",
                    dos = "CRLF",
                    mac = "CR",
                },
            },
            "filetype",
        },
        lualine_y = {
            { trailing, color = "WarningMsg" },
            { mixindent, color = "WarningMsg" },
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
})
