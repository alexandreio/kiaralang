local lpeg = require "lpeg"
local lu = require "luaunit"
local inspect = require "inspect"


local Space = lpeg.S(" \n\t") ^ 0
local Number = lpeg.P("-") ^ -1 * lpeg.R("09") ^ 1 / tonumber
local Numeral = Number * Space
local OpExp = lpeg.C(lpeg.S("^")) * Space
local OpA = lpeg.C(lpeg.S("+-%")) * Space
local OpM = lpeg.C(lpeg.S("*/")) * Space

function fold(lst)
    local acc = lst[1]
    for i = 2, #lst, 2 do
        local op = lst[i]
        local vl = lst[i + 1]

        if (op == "+") then acc = acc + vl
        elseif (op == "-") then acc = acc - vl
        elseif (op == "*") then acc = acc * vl
        elseif (op == "/") then acc = acc / vl
        elseif (op == "%") then acc = acc % vl
        elseif (op == "^") then acc = acc ^ vl
        else
            error("unknow operator")
        end
    end

    return acc
end

local Exp = Space * lpeg.Ct(Numeral * (OpExp * Numeral) ^ 0) / fold
local Term = Space * lpeg.Ct(Exp * (OpM * Exp) ^ 0) / fold
local Sum = Space * lpeg.Ct(Term * (OpA * Term) ^ 0) / fold * -1

function testSum()

    lu.assertEquals(Sum:match("1 + 2"), 3)
    lu.assertEquals(Sum:match("1-2"), -1)
    lu.assertEquals(Sum:match("0 + 1"), 1)
    lu.assertEquals(Sum:match("-1 + 2"), 1)
    lu.assertEquals(Sum:match("0 + 0 + 0 + 0 +0 + 0 "), 0)
    lu.assertEquals(Sum:match("0 - 0 - 0 - 0 -0 - 0 "), 0)
    lu.assertEquals(Sum:match(" 50    + 100       "), 150)
    lu.assertEquals(Sum:match("10 - 3"), 7)
    lu.assertEquals(Sum:match("-1 - -1"), 0)
    lu.assertEquals(Sum:match("-1 + -1"), -2)
    lu.assertEquals(Sum:match("-1 + -1 + -1"), -3)
    lu.assertEquals(Sum:match("2 + 14 * 2"), 30)
    lu.assertEquals(Sum:match("2 + 14 * 2 / 2 - 30"), -14.0)
    lu.assertEquals(Sum:match("4 / 2"), 2.0)
    lu.assertEquals(Sum:match("3 % 1"), 0)
    lu.assertEquals(Sum:match("3 % 2"), 1)
    lu.assertEquals(Sum:match("2 ^ 2"), 4)
    lu.assertEquals(Sum:match("3 % 2 ^ 2"), 3.0)
end

lu.LuaUnit.run()
