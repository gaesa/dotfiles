function GreatTheme(color)
    local home = os.getenv("HOME")
    local command = "test -d " .. home .. "/.local/share/nvim/site/pack/packer/start/everforest"
    if os.execute(command) == true then
        color = "everforest"
    else
        color = "habamax"
    end
    vim.cmd.colorscheme(color)
end

if vim.env.TERM ~= "linux" then
    vim.opt.termguicolors = true
    -- vim.cmd([[let g:everforest_better_performance = 1]])
    vim.g.everforest_better_performance = 1
    -- vim.g.everforest_background = 'soft'
    -- if vim.fn.strftime("%H:%M")
    if os.date("%H:%M") > "06:00" and os.date("%H:%M") < "18:00" then
        vim.opt.background = "light"
        GreatTheme()
        vim.opt.cursorline = true
    else
        vim.opt.background = "dark"
        -- Blow two lines code produce different effects
        -- Maybe related features are not 100% exposed to Lua yet
        -- vim.g.erverforest_transparent_background = 1
        vim.cmd([[let g:everforest_transparent_background = 1]])
        GreatTheme()
        vim.opt.cursorlineopt = "number"
        vim.opt.cursorline = true
    end
    if vim.o.diff == true then
        vim.opt.cursorline = false
    end
else
    if vim.o.diff == true then
        vim.cmd([[colorscheme default]])
    else
        vim.cmd([[colorscheme habamax]])
    end
end
