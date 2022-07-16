lu = require('luaunit')
lpeg = require "lpeg"


function match_sum()
    local Space = lpeg.P(" ") ^ 0
    local Digit = lpeg.P("-") ^ -1 * lpeg.R("09") ^ 1
    local Number = Space * lpeg.C(Digit) * Space
    local Op = Space * lpeg.Cp() * lpeg.P("+") * Space

    return (Number * Op * Number) ^ 1 * (Op * Number) ^ 0
end

function testSum()
    local patt = match_sum()

    lu.assertEquals(table.pack(patt:match("1 + ")), { n = 1 })
    lu.assertEquals(table.pack(patt:match("1+ ")), { n = 1 })
    lu.assertEquals(table.pack(patt:match("+1 ")), { n = 1 })
    lu.assertEquals(table.pack(patt:match("1 + 2")), { "1", 3, "2", n = 3 })
    lu.assertEquals(table.pack(patt:match("12+13+25")), { "12", 3, "13", 6, "25", n = 5 })
    lu.assertEquals(table.pack(patt:match("12+13")), { "12", 3, "13", n = 3 })
end

lu.LuaUnit.run()
