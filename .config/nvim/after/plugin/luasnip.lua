local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
-- local sn = ls.snippet_node
-- local i = ls.insert_node
-- local f = ls.function_node
-- local c = ls.choice_node
-- local d = ls.dynamic_node

ls.add_snippets("all", {
    s("hi", {
        t("Hello, world!"),
    }),
    s({ name = "Shebang for C", trig = "sbc", dscr = "Put Clang shebang for C" }, {
        t([[//usr/bin/clang "$0" -o ${o=$(mktemp)} && exec -a "$0" "${o}" "$@"]]),
    }),
})
