local utils = {}

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
