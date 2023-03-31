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
        t([[//usr/bin/clang "$0" -o "${o=$(mktemp)}" && "${o}" "$@" && rm "${o}" && exit]]),
    }),
    s({ name = "Shebang for Python", trig = "sbpy", dscr = "Put shebang for Python" }, {
        t([[#!/usr/bin/env python3]]),
    }),
    s({ name = "Better bash", trig = "set", dscr = "Fail fast and be aware of exit codes" }, {
        t([[set -Eeuo pipefail]]),
    }),
})
