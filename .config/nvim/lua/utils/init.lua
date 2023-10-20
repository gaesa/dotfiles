local utils = {}

function P(text, level, once)
    if once then
        vim.notify_once(vim.inspect(text), level)
    else
        vim.notify(vim.inspect(text), level, {})
    end
end

utils.string = require("utils.string")
utils.table = require("utils.table")
utils.cond = require("utils.cond")

function utils.range(start, stop, step)
    step = utils.iif(
        step == nil, --
        function()
            return 1
        end,
        function()
            return step
        end
    )
    return function()
        if start < stop then
            local current = start
            start = start + step
            return current
        end
    end
end

return utils
