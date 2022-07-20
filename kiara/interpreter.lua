local pt = require("pt")
local parser = require("kiara.frontend.parser")
local backend_functions = require("kiara.backend.functions")
local backend_build = require("kiara.backend.build")

local params = {...}


if params[1] then
    local file = io.open(params[1], "r")
    io.input(file)
    input = io.read()
    print(input)
    io.close(file)
else
    input = io.read()
end


print("input:", input)
local ast = parser.parse(input)
print("ast:")
print(pt.pt(ast))

local code = backend_functions.compile(ast)
print("\ncode:")
print(pt.pt(code))

local stack = {}
local mem = {k0=0, k1=1, k10=10}
backend_build.run(code, mem, stack)
print("\nstack:")
print(stack[1])