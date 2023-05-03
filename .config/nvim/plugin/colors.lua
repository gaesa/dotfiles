function GreatTheme(color, time)
    local colorpath = vim.fn.stdpath("data") .. "/lazy/" .. color
    if vim.loop.fs_stat(colorpath) then
        color = color
        vim.opt.termguicolors = true
        -- vim.cmd([[let g:everforest_better_performance = 1]])
        vim.g.everforest_better_performance = 1
        -- vim.g.everforest_background = 'soft'
        if time == "night" then
            -- Blow two lines code produce different effects
            -- Maybe related features are not 100% exposed to Lua yet
            -- vim.g.erverforest_transparent_background = 1
            vim.cmd([[let g:everforest_transparent_background = 1]])
        else
            vim.g.erverforest_transparent_background = 0
        end
    else
        if time == "night" then
            color = "habamax"
            vim.opt.cursorline = true
        else
            color = "shine"
        end
    end
    vim.cmd.colorscheme(color)
    if color == "everforest" then
        if time == "day" then
            vim.opt.cursorline = true
        else
            vim.opt.cursorlineopt = "number"
            vim.opt.cursorline = true
        end
        if vim.wo.diff == true then
            vim.opt.cursorline = false
        else
            return
        end
    else
        return
    end
end

if vim.env.TERM ~= "linux" then
    local color = "everforest"
    -- if vim.fn.strftime("%H:%M")
    if os.date("%H:%M") > "06:00" and os.date("%H:%M") < "18:00" then
        local time = "day"
        vim.opt.background = "light"
        GreatTheme(color, time)
    else
        local time = "night"
        vim.opt.background = "dark"
        GreatTheme(color, time)
    end
else
    if vim.wo.diff == true then
        vim.cmd([[colorscheme default]])
    else
        vim.cmd([[colorscheme habamax]])
    end
end
