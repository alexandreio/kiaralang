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

local Compiler = { code = {}, vars = {}, nvars = 0 }

function Compiler:addCode(op)
    local code = self.code
    code[#code + 1] = op
end

function Compiler:var2num(id)
    local num = self.vars[id]
    if not num then
        num = self.nvars + 1
        self.nvars = num
        self.vars[id] = num
    end

    return num
end

function Compiler:codeExp(ast)
    if ast.tag == "number" then
        self:addCode("push")
        self:addCode(ast.val)
    elseif ast.tag == "variable" then
        self:addCode("load")
        self:addCode(self:var2num(ast.var))
    elseif ast.tag == "binop" then
        self:codeExp(ast.e1)
        self:codeExp(ast.e2)
        self:addCode(ops[ast.op])
    else error("invalid tree")
    end
end

function Compiler:codeStat(ast)
    if ast.tag == "assgn" then
        self:codeExp(ast.exp)
        self:addCode("store")
        self:addCode(self:var2num(ast.id))
    elseif ast.tag == "seq" then
        self:codeStat(ast.st1)
        self:codeStat(ast.st2)
    elseif ast.tag == "ret" then
        self:codeExp(ast.exp)
        self:addCode("ret")
    elseif ast.tag == "print" then
        self:codeExp(ast.exp)
        self:addCode("print")
    else error("invalid tree")
    end
end

function Compiler:compile(ast)
    self:codeStat(ast)
    self:addCode("push")
    self:addCode(0)
    self:addCode("ret")
    return self.code
end

return Compiler
