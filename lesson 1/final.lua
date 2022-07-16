local lpeg = require "lpeg"
local lu = require "luaunit"
local inspect = require "inspect"


local Space = lpeg.S(" \n\t") ^ 0
local Number = lpeg.P("-") ^ -1 * lpeg.R("09") ^ 1 / tonumber
local Numeral = Number * Space
local OpExp = lpeg.C(lpeg.S("^")) * Space
local OpM = lpeg.C(lpeg.S("*/%")) * Space
local OpA = lpeg.C(lpeg.S("+-")) * Space

local OP = "(" * Space
local CP = ")" * Space

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

local exp = lpeg.V "Exp"
local term = lpeg.V "Term"
local primary = lpeg.V "Primary"
local exp_term = lpeg.V "ExpTerm"

g = lpeg.P { "Exp",
    Primary = Numeral + OP * exp * CP,
    ExpTerm = Space * lpeg.Ct(primary * (OpExp * primary) ^ 0) / fold,
    Term = Space * lpeg.Ct(exp_term * (OpM * exp_term) ^ 0) / fold,
    Exp = Space * lpeg.Ct(term * (OpA * term) ^ 0) / fold,
}

g = g * -1


local subject = "2 * (2 + 4) * 10"
print(subject)
print(g:match(subject))
-- function testSum()

--     lu.assertEquals(Sum:match("1 + 2"), 3)
--     lu.assertEquals(Sum:match("1-2"), -1)
--     lu.assertEquals(Sum:match("0 + 1"), 1)
--     lu.assertEquals(Sum:match("-1 + 2"), 1)
--     lu.assertEquals(Sum:match("0 + 0 + 0 + 0 +0 + 0 "), 0)
--     lu.assertEquals(Sum:match("0 - 0 - 0 - 0 -0 - 0 "), 0)
--     lu.assertEquals(Sum:match(" 50    + 100       "), 150)
--     lu.assertEquals(Sum:match("10 - 3"), 7)
--     lu.assertEquals(Sum:match("-1 - -1"), 0)
--     lu.assertEquals(Sum:match("-1 + -1"), -2)
--     lu.assertEquals(Sum:match("-1 + -1 + -1"), -3)
--     lu.assertEquals(Sum:match("2 + 14 * 2"), 30)
--     lu.assertEquals(Sum:match("2 + 14 * 2 / 2 - 30"), -14.0)
--     lu.assertEquals(Sum:match("4 / 2"), 2.0)
--     lu.assertEquals(Sum:match("3 % 1"), 0)
--     lu.assertEquals(Sum:match("3 % 2"), 1)
--     lu.assertEquals(Sum:match("2 ^ 2"), 4)
--     lu.assertEquals(Sum:match("3 % 2 ^ 2"), 3.0)
-- end

-- lu.LuaUnit.run()
