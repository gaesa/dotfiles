local hop = require("hop")
local directions = require("hop.hint").HintDirection

hop.setup({})

vim.keymap.set("", "f", function()
    hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = false })
end, { remap = true })

vim.keymap.set("", "F", function()
    hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = false })
end, { remap = true })

vim.keymap.set("", "t", function()
    hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = false, hint_offset = -1 })
end, { remap = true })

vim.keymap.set("", "T", function()
    hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = false, hint_offset = 1 })
end, { remap = true })

vim.keymap.set("", "<leader>l", function()
    hop.hint_vertical({ multi_windows = true })
end, { remap = true })

vim.keymap.set("", "s", function()
    hop.hint_words({ direction = directions.AFTER_CURSOR, current_line_only = false })
end, { remap = true })

vim.keymap.set("", "S", function()
    hop.hint_words({ direction = directions.BEFORE_CURSOR, current_line_only = false })
end, { remap = true })

vim.keymap.set("", "gs", function()
    hop.hint_words({ multi_windows = true })
end, { remap = true })
