local lpeg = require "lpeg"

local grammar = {}

local function nodeNum(num)
    return { tag = "number", val = tonumber(num) }
end

local function nodeVar(var)
    return { tag = "variable", var = var }
end

local function nodeAssgn(id, exp)
    return { tag = "assgn", id = id, exp = exp }
end

local function nodeRet(exp)
    return { tag = "ret", exp = exp }
end

local function nodePrint(exp)
    return { tag = "print", exp = exp }
end

local function nodeSeq(st1, st2)
    if st2 == nil then
        return st1
    end

    return { tag = "seq", st1 = st1, st2 = st2 }
end

local function foldBin(lst)
    local tree = lst[1]

    for i = 2, #lst, 2 do
        tree = { tag = "binop", e1 = tree, op = lst[i], e2 = lst[i + 1] }
    end

    return tree
end

local Alpha = lpeg.R("AZ", "az")
local Digit = lpeg.R("09")
local Underscore = lpeg.P("_")
local QuestionMark = lpeg.P("?")
local AlphaNum = Alpha + Digit + Underscore + QuestionMark

local comment = '#{' * (lpeg.P(1) - '#}')^0 * '#}' + '#' * (lpeg.P(1) - '\n') ^ 0

grammar.maxmatch = 0
grammar.currentline = 0
local Space = lpeg.V "Space"


local HexDigit = lpeg.R("09") ^ 0 * lpeg.R("AF", "af") ^ 0
local HexNumber = (lpeg.P("0x") + lpeg.P("0X")) * HexDigit

local FloatNumber = lpeg.R("09") ^ 1 * lpeg.P(".") * lpeg.R("09") ^ 1

local Number = lpeg.R("09") ^ 1
local ScientificNumber = (FloatNumber + Number) * lpeg.S("eE") * lpeg.P("-") ^ -1 * Number
local Numeral = (ScientificNumber + HexNumber + FloatNumber + Number) / nodeNum * Space

local Assgn = "=" * Space
local SC = ";" * Space

local ID = lpeg.C(Alpha * AlphaNum ^ 0) * Space
local Var = ID / nodeVar

local GEQ = lpeg.P(">=")
local LEQ = lpeg.P("<=")
local LSS = lpeg.P("<")
local GTR = lpeg.P(">")
local EQL = lpeg.P("==")
local NQL = lpeg.P("!=")
local BINCOMP = (GEQ + LEQ + LSS + GTR + EQL + NQL)


local Print = "@" * Space
local ret = "return" * Space
local OP = "(" * Space
local CP = ")" * Space
local OB = "{" * Space
local CB = "}" * Space

local opE = lpeg.C(lpeg.S("^")) * Space
local opM = lpeg.C(lpeg.S("*/%")) * Space
local opA = lpeg.C(lpeg.S "+-") * Space
local opC = (lpeg.C(BINCOMP)) * Space


local Factor = lpeg.V "Factor"
local Pow = lpeg.V "Pow"
local Term = lpeg.V "Term"
local Exp = lpeg.V "Exp"
local Comp = lpeg.V "Comp"
local Stat = lpeg.V "Stat"
local Stats = lpeg.V "Stats"
local Block = lpeg.V "Block"

local Grammar = lpeg.P { "Prog",
    Prog = Space * Stats * -1,
    Stats = Stat * SC * Stats ^ -1 / nodeSeq,
    Block = OB * Stats * SC ^ -1 * CB,
    Stat = Block
        + ID * Assgn * Comp / nodeAssgn
        + ret * Comp / nodeRet
        + Print * Comp / nodePrint,
    Factor = Numeral + OP * Comp * CP + Var,
    Pow = Space * lpeg.Ct(Factor * (opE * Pow) ^ -1) / foldBin,
    Term = Space * lpeg.Ct(Pow * (opM * Pow) ^ 0) / foldBin,
    Exp = Space * lpeg.Ct(Term * (opA * Term) ^ 0) / foldBin,
    Comp = Space * lpeg.Ct(Exp * (opC * Exp) ^ 0) / foldBin,
    Space = (lpeg.S(" \t\n") + comment) ^ 0 *
        lpeg.P(function(s, p)

            if string.sub(s, p - 1, p - 1) == "\n" then
                grammar.currentline = grammar.currentline + 1
            end

            grammar.maxmatch = math.max(grammar.maxmatch, p)
            return true
        end)

}

grammar.Grammar = Grammar


return grammar
