local pt = require("pt")

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

local Compiler = { funcs = {}, vars = {}, nvars = 0, locals = {} }

function Compiler:addCode(op)
    local code = self.code
    code[#code + 1] = op
end

function Compiler:var2num(id)
    if self.vars[id] == nil then
        error("variable " .. id .. " is not defined")
    end
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

function Compiler:findLocal(name) 
    local loc = self.locals
    for i = #loc, 1, -1 do
        if name == loc[i] then
            return i
        end
    end

    local params = self.params
    for i = 1, #params do
        if name == params[i] then
            return -(#params - i)
        end
    end

    return nil
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

function Compiler:codeCall(ast)
    local func = self.funcs[ast.fname]

    if not func then
        error("undefined function " .. ast.fname)
    end
    
    local args = ast.args
    if func.params ~= nil and (#func.params ~= #args) then
        error("wrong number of arguments to " .. ast.fname)
    end

    if func.code ~= nil then
        for i = 1, #args do
            self:codeExp(args[i])
        end

        self:addCode("call")
        self:addCode(func.code)
    else
        error("function: " .. ast.fname .. " not declared")
    end
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
    elseif ast.tag == "call" then
        self:codeCall(ast)
    elseif ast.tag == "variable" then
        local idx = self:findLocal(ast.var)
        if idx then
            self:addCode("loadL")
            self:addCode(idx)
        else            
            self:addCode("load")
            self:addCode(self:var2num(ast.var))
        end
    elseif ast.tag == "and1" then
        self:codeExp(ast.exp[1])
        local jmp = self:codeJmp("jmpZP")
        self:codeExp(ast.exp[2])
        self:fixJmp2here(jmp)
    elseif ast.tag == "or1" then
        self:codeExp(ast.exp[1])
        local jmp = self:codeJmp("jmpNZP")
        self:codeExp(ast.exp[2])
        self:fixJmp2here(jmp)
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
        local idx = self:findLocal(lhs.var)
        if idx then
            self:addCode("storeL")
            self:addCode(idx)
        else
            self:addCode("store")
            self:addCode(self:var2num(lhs.var))
        end
    elseif lhs.tag == "indexed" then
        self:codeExp(lhs.array)
        self:codeExp(lhs.index)
        self:codeExp(ast.exp)
        self:addCode("setarray")
    else error("unknow tag")
    end
end

function Compiler:codeBlock (ast)
    local oldLevel = #self.locals
    self:codeStat(ast.body)
    local diff = #self.locals - oldLevel
    if diff > 0 then
        for i = 1, diff do
            table.remove(self.locals)
        end
        self:addCode("pop")
        self:addCode(diff)
    end
end

function Compiler:codeStat(ast)
    if ast.tag == "assgn" then
        self:codeAssgn(ast)
    elseif ast.tag == "local" then
        for i = 1, #self.locals do
            if self.locals[i] == ast.name then
                error("local variable: " .. ast.name .. " already declared locally")
            end
        end

        if ast.init == nil then
            ast.init = {tag = "number", val = 0}
        end
        -- print(pt.pt(ast.init))
        self:codeExp(ast.init)
        self.locals[#self.locals + 1] = ast.name
    elseif ast.tag == "call" then
        self:codeCall(ast)
        self:addCode("pop")
        self:addCode(1)
    elseif ast.tag == "block" then
        self:codeBlock(ast)
    elseif ast.tag == "seq" then
        self:codeStat(ast.st1)
        self:codeStat(ast.st2)
    elseif ast.tag == "ret" then
        self:codeExp(ast.exp)
        self:addCode("ret")
        self:addCode(#self.locals + #self.params)
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

function Compiler:codeFunction(ast)
    local code = {}
    if self.funcs[ast.name] ~= nil and self.funcs[ast.name].foward == nil then
        error("function '" .. ast.name .. "' already declared")
    end

    local params = {}
    for i = 1, #ast.params do
        local cur_param = ast.params[i]
        if params[cur_param] ~= nil then
            error("param " .. cur_param .. " already declared")
        else params[cur_param] = true
            
        end
    end

    if ast.name == "main" and #ast.params > 0 then
        error("main function must have no parameters")
    end

    self.funcs[ast.name] = {foward = true}

    if ast.body then
        self.funcs[ast.name] = {code = code, foward = nil, params=ast.params}
        self.code = code
        self.params = ast.params
        self:codeStat(ast.body)
        self:addCode("push")
        self:addCode(0)
        self:addCode("ret")
        self:addCode(#self.locals + #self.params)
    end
end


function Compiler:compile(ast)
    for i = 1, #ast do
        self:codeFunction(ast[i])
    end

    local main = self.funcs["main"]
    if not main then
        error("no function 'main'")
    end


    return main.code
end

function Compiler:clean()
    self.funcs = {}
    self.vars = {}
    self.nvars = {}
    self.locals = {}
end

return Compiler
