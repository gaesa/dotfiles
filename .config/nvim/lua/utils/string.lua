local M = {}

function M.rstrip(s)
    return string.gsub(s, "%s+$", "")
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

function M.pattern_quote(s)
    return string.gsub(s, ".", special_chars)
end

return M
