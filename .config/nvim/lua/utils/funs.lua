local M = {}

function M.filter_return(operation, callback)
    return function(...)
        return callback(operation(...))
    end
end

return M
