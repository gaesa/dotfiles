local M = {}

---@generic T
---@param v T | nil
---@param default T
---@return T
function M.unwrap_or(v, default)
    if v == nil then
        return default
    else
        return v
    end
end

---@generic T
---@param v T | nil
---@param default fun(): T
---@return T
function M.unwrap_or_else(v, default)
    if v == nil then
        return default()
    else
        return v
    end
end

return M
