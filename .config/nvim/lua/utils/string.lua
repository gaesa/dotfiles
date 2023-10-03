local M = {}

function M.rstrip(s)
    return string.gsub(s, "%s+$", "")
end

function M.startswith(s, prefix)
    return string.find(s, prefix, 1, true) == 1
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
