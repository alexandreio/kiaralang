lu = require('luaunit')
lpeg = require "lpeg"


function match_sum()
    local Space = lpeg.P(" ") ^ 0
    local Digit = lpeg.P("-") ^ -1 * lpeg.R("09") ^ 1
    local Number = Digit * Space
    local Op = lpeg.P("+") * Space

    return Space * (Number * Op * Number) ^ 1 * (Op * Number) ^ 0 * -1
end

function testSum()
    local sum = match_sum()

    lu.assertEquals(sum:match("1+2"), 4)
    lu.assertEquals(sum:match("-1+2"), 5)
    lu.assertEquals(sum:match("-1 + -2"), 8)
    lu.assertEquals(sum:match("1 + 2"), 6)
    lu.assertEquals(sum:match("1  + 2"), 7)
    lu.assertEquals(sum:match("10 + 2"), 7)
    lu.assertEquals(sum:match("10 + 20"), 8)
    lu.assertEquals(sum:match("100 + 200"), 10)
    lu.assertEquals(sum:match(" 100 + 200"), 11)
    lu.assertEquals(sum:match("100 + 200 "), 11)
    lu.assertEquals(sum:match(" 100 + 200 "), 12)
    lu.assertEquals(sum:match("1 + 2 + 3"), 10)
    lu.assertEquals(sum:match("10 + 2 + 3"), 11)
    lu.assertEquals(sum:match("10 + 20 + 30"), 13)
    lu.assertEquals(sum:match("10+20+30"), 9)
    lu.assertEquals(sum:match(" 10+20+     30"), 15)
    lu.assertEquals(sum:match("10 + 2 + 3 + 4 + 5"), 19)
    lu.assertEquals(sum:match("10 + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9 + 10"), 40)
    lu.assertEquals(sum:match("1+"), nil)
    lu.assertEquals(sum:match("+1"), nil)
    lu.assertEquals(sum:match("+ -1"), nil)
end

lu.LuaUnit.run()
