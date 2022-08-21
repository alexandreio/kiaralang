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

function Compiler:currentPosition()
    return #self.code
end

function Compiler:codeJmpB(op, label)
    self:addCode(op)
    self:addCode(label)
end

function Compiler:codeJmp(op)
    self:addCode(op)
    self:addCode(0)
    return self:currentPosition()
end

function Compiler:fixJmp2here(jmp)
    self.code[jmp] = self:currentPosition()
end

function Compiler:codeExp(ast)
    if ast.tag == "number" then
        self:addCode("push")
        self:addCode(ast.val)
    elseif ast.tag == "minus" then
        self:codeExp(ast.e1)
        self:addCode("minus")
    elseif ast.tag == "not" then
        self:codeExp(ast.e1)
        self:addCode("not")
    elseif ast.tag == "variable" then
        self:addCode("load")
        self:addCode(self:var2num(ast.var))
    elseif ast.tag == "indexed" then
        self:codeExp(ast.array)
        self:codeExp(ast.index)
        self:addCode("getarray")
    elseif ast.tag == "new" then
        self:codeExp(ast.size)
        self:addCode("newarray")
    elseif ast.tag == "multnew" then
        for i = 1, #ast.lvls do
            self:codeExp(ast.lvls[i])
        end
        self:addCode("push")
        self:addCode(#ast.lvls)
        self:addCode("multnewarray")
    elseif ast.tag == "binop" then
        self:codeExp(ast.e1)
        self:codeExp(ast.e2)
        self:addCode(ops[ast.op])
    else error("invalid tree")
    end
end

function Compiler:codeAssgn(ast)
    local lhs = ast.lhs
    if lhs.tag == "variable" then
        self:codeExp(ast.exp)
        self:addCode("store")
        self:addCode(self:var2num(lhs.var))
    elseif lhs.tag == "indexed" then
        self:codeExp(lhs.array)
        self:codeExp(lhs.index)
        self:codeExp(ast.exp)
        self:addCode("setarray")
    else error("unknow tag")
    end
end

function Compiler:codeStat(ast)
    if ast.tag == "assgn" then
        self:codeAssgn(ast)
    elseif ast.tag == "seq" then
        self:codeStat(ast.st1)
        self:codeStat(ast.st2)
    elseif ast.tag == "ret" then
        self:codeExp(ast.exp)
        self:addCode("ret")
    elseif ast.tag == "print" then
        self:codeExp(ast.exp)
        self:addCode("print")
    elseif ast.tag == "while1" then
        local ilabel = self:currentPosition()
        self:codeExp(ast.cond)
        local jmp = self:codeJmp("jmpZ")
        self:codeStat(ast.body)
        self:codeJmpB("jmp", ilabel)
        self:fixJmp2here(jmp)
    elseif ast.tag == "if1" then
        self:codeExp(ast.cond)
        local jmp = self:codeJmp("jmpZ")
        self:codeStat(ast.th)

        if ast.el == nil then
            self:fixJmp2here(jmp)
        else
            local jmp2 = self:codeJmp("jmp")
            self:fixJmp2here(jmp)
            self:codeStat(ast.el)
            self:fixJmp2here(jmp2)
        end
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
