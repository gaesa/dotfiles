local function load_theme(color)
    vim.opt.background = color

    local function set_theme(theme)
        vim.opt.termguicolors = true
        vim.cmd([[let g:everforest_better_performance = 1]])
        -- vim.g.everforest_background = 'soft'

        if color == "dark" then
            -- Blow two lines code produce different effects
            -- vim.g.erverforest_transparent_background = 1
            vim.cmd([[let g:everforest_transparent_background = 1]])
            vim.cmd.colorscheme(theme)
            vim.opt.cursorlineopt = "number"
            vim.opt.cursorline = true
        else
            vim.cmd([[let g:everforest_transparent_background = 0]])
            vim.cmd.colorscheme(theme)
            vim.opt.cursorline = true
        end

        if vim.wo.diff then
            vim.opt.cursorline = false
        else
            return
        end
    end

    local function set_fallback_theme()
        local theme
        if color == "dark" then
            vim.opt.cursorline = true
            theme = "habamax"
        else
            theme = "shine"
        end
        vim.cmd.colorscheme(theme)
    end

    local theme = "everforest"
    local colorpath = vim.fn.stdpath("data") .. "/lazy/" .. theme
    if vim.loop.fs_stat(colorpath) then
        set_theme(theme)
    else
        set_fallback_theme()
    end
end

local function auto_switch_theme()
    local hour = tonumber(vim.fn.strftime("%H"))
    local color
    if hour >= 6 and hour < 18 then
        color = "light"
    else
        color = "dark"
    end
    load_theme(color)
end

local function main()
    if vim.env.TERM ~= "linux" then
        ---@diagnostic disable-next-line: undefined-field
        local color = vim.g.mycolor
        if color then
            load_theme(color)
        else
            auto_switch_theme()
        end
    else
        if vim.wo.diff then
            vim.cmd.colorscheme("default")
        else
            vim.cmd.colorscheme("habamax")
        end
    end
end

main()
