local M = {}

function M.iif(predicate, consequent, alternative)
    if predicate then
        return consequent()
    else
        return alternative()
    end
end

function M.cond(...)
    local args = { ... }
    for _, tuple in ipairs(args) do
        local condition, action = unpack(tuple)
        if condition() then
            return action()
        end
    end
end

return M
