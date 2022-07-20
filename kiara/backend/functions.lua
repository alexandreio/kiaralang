local functions = {}

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


local function addCode(state, op)
    local code = state.code
    code[#code+1] = op
end


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

function functions.compile (ast)
    local state = {code = {}, vars={}, nvars=0}
    codeStat(state, ast)
    addCode(state, "push")
    addCode(state, 0)
    addCode(state, "ret")
    return state.code
end

return functions