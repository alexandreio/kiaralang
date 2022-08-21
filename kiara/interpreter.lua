local pt = require("pt")
local parser = require("kiara.frontend.parser")
local compiler = require("kiara.backend.compiler")
local backend_build = require("kiara.backend.build")

local params = { ... }


if params[1] then
    local file = io.open(params[1], "r")
    io.input(file)
    input = io.read("a")
    io.close(file)
else
    input = io.read()
end


print("input:", input)
print("")
local ast = parser.parse(input)
print("ast:")
print(pt.pt(ast))

local code = compiler:compile(ast)
print("\ncode:")
print(pt.pt(code))

local stack = {}
local mem = { k0 = 0, k1 = 1, k10 = 10 }
backend_build.run(code, mem, stack, 0)
print("\nstack:")
print(stack[1])
