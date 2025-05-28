local M = {}

---@generic A, B, R
---@param operation fun(...: A): B
---@param callback fun(result: B): R
---@return fun(...: A): R
function M.filter_return(operation, callback)
    return function(...)
        return callback(operation(...))
    end
end

return M
