local M = {}

---@param s string
---@return string
function M.rstrip(s)
    local result, _ = string.gsub(s, "%s+$", "")
    return result
end

local special_chars = {
    ["("] = "%(",
    [")"] = "%)",
    ["."] = "%.",
    ["%"] = "%%",
    ["+"] = "%+",
    ["-"] = "%-",
    ["*"] = "%*",
    ["?"] = "%?",
    ["["] = "%[",
    ["]"] = "%]",
    ["^"] = "%^",
    ["$"] = "%$",
}

---@param s string
---@return string
function M.pattern_quote(s)
    local result, _ = string.gsub(s, ".", special_chars)
    return result
end

return M
