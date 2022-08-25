local pt = require "pt"
local lpeg = require "lpeg"

local grammar = {}

local function node(tag, ...)
    local labels = table.pack(...)
    local params = table.concat(labels, ", ")
    local fields = string.gsub(params, "(%w+)", "%1 = %1")
    print(pt.pt(labels))
    print(pt.pt(params))
    print(pt.pt(fields))
    
    print("---")
    local code = string.format(
        "return function (%s) return {tag = '%s', %s} end",
        params, tag, fields
    )

    return load(code)()

end

local function nodeNum(num)
    return { tag = "number", val = tonumber(num) }
end


local function nodeSeq(st1, st2)
    if st2 == nil then
        return st1
    end

    return { tag = "seq", st1 = st1, st2 = st2 }
end


local function nodeNot (exp)
    return {tag="not", e1=exp[1]}
end


local function nodeMinus (exp)
    return {tag="minus", e1=exp[1]}
end


local function foldBin(lst)
    local tree = lst[1]

    for i = 2, #lst, 2 do
        tree = { tag = "binop", e1 = tree, op = lst[i], e2 = lst[i + 1] }
    end

    return tree
end

local function foldIndex(lst)
    local tree = lst[1]

    for i = 2, #lst do
        tree = {tag = "indexed", array=tree, index=lst[i]}
    end

    return tree
end

local function foldNew(lst)
    if #lst == 1 then
        print(">>" .. lst[1].val)
        return {tag = "new", size = {tag="number", val=lst[1].val}}
    end

    local tree = {tag = "multnew", lvls= {}}
    for i = 1, #lst do
        tree.lvls[i] = lst[i]
    end

    -- print(pt.pt(tree))

    return tree
end


local Alpha = lpeg.R("AZ", "az")
local Digit = lpeg.R("09")
local Underscore = lpeg.P("_")
local QuestionMark = lpeg.P("?")
local AlphaNum = Alpha + Digit + Underscore + QuestionMark

local Space = lpeg.V "Space"

local reserved = {"return", "if", "elseif", "else", "while", "new", "function"}
local excluded = lpeg.P(false)
for i = 1, #reserved do
    excluded = excluded +  reserved[i]
end
excluded = excluded * -AlphaNum

local function T(t)
    return t * Space
end

local function Rw(t)
    assert(excluded:match(t))
    return t * - AlphaNum * Space
end

local HexDigit = lpeg.R("09") ^ 0 * lpeg.R("AF", "af") ^ 0
local HexNumber = (lpeg.P("0x") + lpeg.P("0X")) * HexDigit

local FloatNumber = lpeg.R("09") ^ 1 * lpeg.P(".") * lpeg.R("09") ^ 1

local Number = lpeg.R("09") ^ 1
local ScientificNumber = (FloatNumber + Number) * lpeg.S("eE") * lpeg.P("-") ^ -1 * Number
local Numeral = (ScientificNumber + HexNumber + FloatNumber + Number) / nodeNum * Space


-- local ID = (lpeg.C(Alpha * AlphaNum ^ 0) -excluded) * Space
local ID = lpeg.V"ID"
local Var = ID / node("variable", "var")

local GEQ = lpeg.P(">=")
local LEQ = lpeg.P("<=")
local LSS = lpeg.P("<")
local GTR = lpeg.P(">")
local EQL = lpeg.P("==")
local NQL = lpeg.P("!=")
local BINCOMP = (GEQ + LEQ + LSS + GTR + EQL + NQL)


local Print = "@" * Space

local opE = lpeg.C(lpeg.S("^")) * Space
local opM = lpeg.C(lpeg.S("*/%")) * Space
local opA = lpeg.C(lpeg.S "+-") * Space
local opC = (lpeg.C(BINCOMP)) * Space

local Lhs = lpeg.V"Lhs"
local Call = lpeg.V"Call"
local Factor = lpeg.V "Factor"
local Pow = lpeg.V "Pow"
local Term = lpeg.V "Term"
local Exp = lpeg.V "Exp"
local Comp = lpeg.V "Comp"
local Stat = lpeg.V "Stat"
local Stats = lpeg.V "Stats"
local Block = lpeg.V "Block"
local Minus = lpeg.V "Minus"
local Not = lpeg.V "Not"
local If = lpeg.V"If"
local Else = lpeg.V"Else"
local FuncDec = lpeg.V"FuncDec"

grammar.maxmatch = 0
grammar.currentline = 1
grammar.currentcol = 1


local simpleComment = '#' * (lpeg.P(1) - '\n') ^ 0
local blockComment = '#{' * (lpeg.P(1) - '#}')^0  * '#}'
local comment =  blockComment + simpleComment

local Grammar = lpeg.P { 
    "Prog",
    Prog = Space * lpeg.Ct(FuncDec^1)  * -1,
    FuncDec = (Rw"function" * ID * T"(" * T")" * Block
            + Rw"function" * ID * T"(" * T");") / node("function", "name", "body"),
    Stats = Stat *(T";" * Stats) ^ -1 / nodeSeq,
    Block = T"{" * Stats * T";"^-1 * T"}",
    Stat = T";"
        + T"{" * T"}"
        + Block
        + If
        + Rw"while" * Exp * Block / node("while1", "cond", "body")
        + Call
        + Lhs * T"=" * Exp / node("assgn", "lhs", "exp")
        + Rw"return" * Exp * T";" ^ - 1/ node("ret", "exp")
        + Print * Exp / node("print", "exp"),
    If = Rw"if" * Exp * Block * (Else ^ -1) / node("if1", "cond", "th", "el"),
    Else = (Rw"else" * Block) + (Rw"elseif" * Exp * Block * (Else ^ -1)) / node("if1", "cond", "th", "el"),
    Lhs = lpeg.Ct(Var * (T"[" * Exp * T"]")^0) / foldIndex,
    Call = ID * T"(" * T")" / node("call", "fname"),
    Factor = lpeg.Ct( Rw"new" *  (T"[" * Exp * T"]")^0) / foldNew
            + Not 
            + Minus 
            + Numeral 
            + T"(" * Comp * T")" 
            + Call
            + Lhs,
    Pow = Space * lpeg.Ct(Factor * (opE * Pow) ^ -1) / foldBin,
    Term = Space * lpeg.Ct(Pow * (opM * Pow) ^ 0) / foldBin,
    Exp = Space * lpeg.Ct(Term * (opA * Term) ^ 0) / foldBin,
    Comp = Space * lpeg.Ct(Exp * (opC * Exp) ^ 0) / foldBin,
    Not = Space * lpeg.Ct(T"!" * Comp ^0) / nodeNot,
    Minus = Space * lpeg.Ct(T"-" * Comp ^0) / nodeMinus,
    Space = (comment + lpeg.S(" \n\t")) ^ 0 *
        lpeg.P(function(s, p)
            grammar.currentcol = grammar.currentcol + 1
            grammar.maxmatch = math.max(grammar.maxmatch, p)
            return true
        end),
    ID = (lpeg.C(Alpha * AlphaNum ^ 0) -excluded) * Space

}

grammar.Grammar = Grammar


return grammar
