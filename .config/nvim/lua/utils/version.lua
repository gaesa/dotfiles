---@class Version
---@field major integer
---@field minor integer
---@field patch integer
local Version = {}
Version.__index = Version

---Create a new Version object.
---@param major integer
---@param minor integer|nil
---@param patch integer|nil
---@return Version
function Version.new(major, minor, patch)
    if minor == nil then
        minor = 0
    end
    if patch == nil then
        patch = 0
    end
    local self = {
        major = major,
        minor = minor,
        patch = patch,
    }
    setmetatable(self, Version)
    return self
end

---Compare if version `a` is less than version `b`.
---@param a Version
---@param b Version
---@return boolean
function Version.__lt(a, b)
    if a.major ~= b.major then
        return a.major < b.major
    elseif a.minor ~= b.minor then
        return a.minor < b.minor
    else
        return a.patch < b.patch
    end
end

---Compare if version `a` is equal to version `b`.
---@param a Version
---@param b Version
---@return boolean
function Version.__eq(a, b)
    return a.major == b.major and a.minor == b.minor and a.patch == b.patch
end

---Compare if version `a` is less than or equal to version `b`.
---@param a Version
---@param b Version
---@return boolean
function Version.__le(a, b)
    return a < b or a == b
end

---Convert the version to a string.
---@return string
function Version:__tostring()
    return string.format("%d.%d.%d", self.major, self.minor, self.patch)
end

---Parse a version from a string of format "x.y.z".
---@param str string
---@return Version
function Version.from_string(str)
    ---@type string|nil, string|nil, string|nil
    local major, minor, patch = str:match("^(%d+)%.(%d+)%.(%d+)$")
    if major == nil or minor == nil or patch == nil then
        error("Invalid version string: " .. tostring(str))
    else
        local major_n = tonumber(major)
        ---@cast major_n integer
        local minor_n = tonumber(minor)
        ---@cast minor_n integer
        local patch_n = tonumber(patch)
        ---@cast patch_n integer

        return Version.new(major_n, minor_n, patch_n)
    end
end

---@return Version
function Version.nvim()
    local v = vim.version()
    return Version.new(v.major, v.minor, v.patch)
end

return Version
