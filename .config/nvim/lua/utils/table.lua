local M = {}

function M.keys(tbl)
    local keys = {}
    for k, _ in pairs(tbl) do
        table.insert(keys, k)
    end
    return keys
end

function M.copy(tbl)
    local copied = {}
    for k, v in pairs(tbl) do
        copied[k] = v
    end
    return copied
end

function M.len(tbl)
    return #tbl
end

function M.for_each(operation, sequence)
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

function M.map(operation, sequence)
    local res = {}
    M.for_each( --
        function(ele)
            table.insert(res, operation(ele))
        end,
        sequence
    )
    return res
end

function M.filter(operation, sequence)
    local res = {}
    M.for_each( --
        function(ele)
            if operation(ele) then
                table.insert(res, ele)
            end
        end,
        sequence
    )
    return res
end

return M
