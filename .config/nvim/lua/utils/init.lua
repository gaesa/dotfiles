local utils = {}

function P(text, level, once)
    if once then
        vim.notify_once(vim.inspect(text), level)
    else
        vim.notify(vim.inspect(text), level, {})
    end
end

utils.string = require("utils.string")

function utils.iif(predicate, consequent, alternative)
    if predicate then
        return consequent()
    else
        return alternative()
    end
end

function utils.cond(...)
    local args = { ... }
    for _, tuple in ipairs(args) do
        local condition, action = unpack(tuple)
        if condition() then
            return action()
        end
    end
end

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

function utils.for_each(operation, sequence)
    if type(sequence) == "function" then
        for v in sequence do
            operation(v)
        end
    else
        for i, v in pairs(sequence) do
            operation(v, i)
        end
    end
end

return utils
