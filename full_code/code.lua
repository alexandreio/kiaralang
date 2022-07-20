local lpeg = require "lpeg"
local pt = require "pt"

-- frontend
local function nodeNum (num)
    return {tag = "number", val = tonumber(num)}
end

local function nodeVar (var)
    return {tag = "variable", var = var}
end

local function nodeAssgn (id, exp)
    return {tag = "assgn", id = id, exp = exp}
end

local function nodeRet (exp)
    return {tag = "ret", exp = exp}
end

local function nodePrint (exp)
    return {tag = "print", exp = exp}
end

local function nodeSeq (st1, st2)
    if st2 == nil then
        return st1
    end

    return {tag = "seq", st1 = st1, st2 = st2}
end


local Alpha = lpeg.R("AZ", "az")
local Digit = lpeg.R("09")
local Underscore = lpeg.P("_")
local QuestionMark = lpeg.P("?")
local AlphaNum = Alpha + Digit + Underscore + QuestionMark

local Space = lpeg.S(" \t\n")^0

local HexDigit = lpeg.R("09")^0 * lpeg.R("AF", "af")^0
local HexNumber = (lpeg.P("0x") + lpeg.P("0X")) * HexDigit

local FloatNumber = lpeg.R("09") ^ 1 * lpeg.P(".") * lpeg.R("09") ^ 1

local Number =  lpeg.R("09") ^ 1
local  ScientificNumber = (FloatNumber + Number) * lpeg.S("eE") * lpeg.P("-") ^ -1 * Number
local Numeral = (ScientificNumber  + HexNumber+ FloatNumber  + Number) / nodeNum * Space

local Assgn = "=" * Space
local SC = ";" * Space

local ID = lpeg.C(Alpha * AlphaNum^0) * Space
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
local opA = lpeg.C(lpeg.S"+-") * Space
local opC = (lpeg.C(BINCOMP)) * Space



local function foldBin(lst)
    local tree = lst[1]
    
    for i = 2, #lst, 2 do
        tree = {tag = "binop", e1 = tree, op = lst[i], e2 = lst[i + 1]}
    end

    return tree
end


local Factor = lpeg.V"Factor"
local Pow = lpeg.V"Pow"
local Term = lpeg.V"Term"
local Exp = lpeg.V"Exp"
local Comp = lpeg.V"Comp"
local Stat = lpeg.V"Stat"
local Stats = lpeg.V"Stats"
local Block = lpeg.V"Block"

local grammar = lpeg.P{"Stats",
    Stats = Stat * (SC * Stats)^-1 / nodeSeq,
    Block = OB * Stats * SC^-1 * CB,
    Stat = Block 
         + ID * Assgn * Comp / nodeAssgn 
         + ret * Comp / nodeRet
         + Print * Comp / nodePrint,
    Factor = Numeral + OP * Comp * CP + Var,
    Pow = Space * lpeg.Ct(Factor * (opE * Pow) ^-1) /foldBin,
    Term = Space * lpeg.Ct(Pow * (opM * Pow) ^ 0) / foldBin,
    Exp = Space * lpeg.Ct(Term * (opA * Term) ^ 0) / foldBin,
    Comp = Space * lpeg.Ct(Exp * (opC * Exp) ^0) / foldBin,

}

grammar = Space * grammar * -1




local function parse (input)
    return grammar:match(input)
end

-- backend

local function addCode(state, op)
    local code = state.code
    code[#code+1] = op
end

local ops = {
             ["+"] = "add",
             ["-"] = "sub",
             ["*"] = "mul",
             ["/"] = "div",
             ["%"] = "rem",
             ["^"] = "pow",
             ["<"] = "sml",
             [">"] = "big",
             [">="] = "big_eq",
             ["<="] = "sml_eql",
             ["=="] = "equal",
             ["!="] = "not_equal",
            }

local function var2num (state, id)
    local num = state.vars[id]
    if not num then
        num = state.nvars + 1
        state.nvars = num
        state.vars[id] = num
    end

    return num
end

local function codeExp (state, ast)
    if ast.tag == "number" then
        addCode(state, "push")
        addCode(state, ast.val)
    elseif ast.tag == "variable" then
        addCode(state, "load")
        addCode(state, var2num(state, ast.var))
    elseif ast.tag == "binop" then
        codeExp(state, ast.e1)
        codeExp(state, ast.e2)
        addCode(state, ops[ast.op])
    else error("invalid tree")
    end
end

local function codeStat (state, ast)
    if ast.tag == "assgn" then
        codeExp(state, ast.exp)
        addCode(state, "store")
        addCode(state, var2num(state, ast.id))
    elseif ast.tag == "seq" then
        codeStat(state, ast.st1)
        codeStat(state, ast.st2)
    elseif ast.tag == "ret" then
        codeExp(state, ast.exp)
        addCode(state, "ret")
    elseif ast.tag == "print" then
        codeExp(state, ast.exp)
        addCode(state, "ret")
    else error("invalid tree")
    end
end

local function compile (ast)
    local state = {code = {}, vars={}, nvars=0}
    codeStat(state, ast)
    addCode(state, "push")
    addCode(state, 0)
    addCode(state, "ret")
    return state.code
end

local function run (code, mem, stack)
    local pc = 1
    local top = 0

    while true do
        --[[
            io.write("--> ")
            for i = 1, top do io.write(stack[i], " ") end
            io.write("\n", code[pc], "\n")
        -- ]]
        if code[pc] == "ret" then
            return
        elseif code[pc] == "push" then
            pc = pc + 1
            top = top + 1
            stack[top] = code[pc]
        elseif code[pc] == "add" then
            stack[top -1] = stack[top -1] + stack[top]
            top = top - 1
        elseif code[pc] == "sub" then
            stack[top -1] = stack[top -1] - stack[top]
            top = top - 1
        elseif code[pc] == "mul" then
            stack[top -1] = stack[top -1] * stack[top]
            top = top - 1
        elseif code[pc] == "div" then
            stack[top -1] = stack[top -1] / stack[top]
            top = top - 1
        elseif code[pc] == "rem" then
            stack[top -1] = stack[top -1] % stack[top]
            top = top - 1
        elseif code[pc] == "pow" then
            stack[top -1] =  stack[top -1] ^ stack[top]
            top = top - 1
        elseif code[pc] == "sml" then
            stack[top -1] =  stack[top -1] < stack[top]
            top = top - 1
        elseif code[pc] == "big" then
            stack[top -1] =  stack[top -1] > stack[top]
            top = top - 1
        elseif code[pc] == "big_eq" then
            stack[top -1] =  stack[top -1] >= stack[top]
            top = top - 1
        elseif code[pc] == "sml_eq" then
            stack[top -1] =  stack[top -1] <= stack[top]
            top = top - 1
        elseif code[pc] == "equal" then
            stack[top -1] =  stack[top -1] == stack[top]
            top = top - 1
        elseif code[pc] == "not_equal" then
            stack[top -1] =  stack[top -1] ~= stack[top]
            top = top - 1
        elseif code[pc] == "load" then
            pc = pc + 1
            local id = code[pc]
            top = top + 1
            stack[top] = mem[id]
        elseif code[pc] == "store" then
            pc = pc + 1
            local id = code[pc]
            mem[id] = stack[top]
            top = top - 1
        else error("unknow instruction")
        end
        pc = pc + 1
    end
end

local input = io.read()
print("input:", input)
local ast = parse(input)
print("ast:")
print(pt.pt(ast))

local code = compile(ast)
print("\ncode:")
print(pt.pt(code))

local stack = {}
local mem = {k0=0, k1=1, k10=10}
run(code, mem, stack)
print("\nstack:")
print(stack[1])