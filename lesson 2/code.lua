local lpeg = require "lpeg"
local pt = require "pt"

-- frontend
local function node (num)
    return {tag = "number", val = tonumber(num)}
end

local Space = lpeg.S(" \t\n")^0
local HexPrefix = lpeg.P("0x")^-1 + lpeg.P("0X")^-1
local Number = lpeg.P("-") ^ -1 * lpeg.R("09") ^ 1
local Numeral = ((HexPrefix * lpeg.R("09")^1) + (Number)) / node * Space
local BigSml = lpeg.S"><" * lpeg.P("=")^-1
local Equal = lpeg.P("==")
local NotEqual = lpeg.P("!=")

local OP = "(" * Space
local CP = ")" * Space

local opE = lpeg.C(lpeg.S("^")) * Space
local opM = lpeg.C(lpeg.S("*/%")) * Space
local opA = lpeg.C(lpeg.S"+-") * Space
local opC = (lpeg.C(BigSml + Equal + NotEqual)) * Space

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

local grammar = lpeg.P{"Comp",
    Factor = Numeral + OP * Exp * CP,
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

local function codeExp (state, ast)
    if ast.tag == "number" then
        addCode(state, "push")
        addCode(state, ast.val)
    elseif ast.tag == "binop" then
        codeExp(state, ast.e1)
        codeExp(state, ast.e2)
        addCode(state, ops[ast.op])
    else error("invalid tree")
    end
end

local function compile (ast)
    local state = {code = {} }
    codeExp(state, ast)
    return state.code
end

local function run (code, stack)
    local pc = 1
    local top = 0

    while pc <= #code do
        if code[pc] == "push" then
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
        else error("unknow instruction")
        end
        pc = pc + 1
    end
end

local input = io.read()
print("input:", input)
local ast = parse(input)
-- print("ast:")
-- print(pt.pt(ast))

local code = compile(ast)
-- print("\ncode:")
-- print(pt.pt(code))

local stack = {}
run(code, stack)
print("\nstack:")
print(stack[1])