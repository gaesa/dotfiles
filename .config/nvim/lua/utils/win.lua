local M = {}

---@generic T
---@param fn fun(): T|nil
function M.with_cursor_unchanged(fn)
    local winid = 0
    local cursor_position = vim.api.nvim_win_get_cursor(winid)
    fn()
    vim.api.nvim_win_set_cursor(winid, cursor_position)
end

return M
