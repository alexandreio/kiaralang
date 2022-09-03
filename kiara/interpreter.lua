local pt = require("pt")
local parser = require("kiara.frontend.parser")
local compiler = require("kiara.backend.compiler")
local backend_build = require("kiara.backend.build")

local params = { ... }


local function run(params, debug)
    local input = nil
    if params[1] then
        local file = io.open(params[1], "r")
        io.input(file)
        input = io.read("a")
        io.close(file)
    else
        input = io.read()
    end

    if debug == true then
        print("input:", input)
        print("")
    end
    -- 
    -- 
    local ast = parser.parse(input)
    if debug == true then
        print("ast:")
        print(pt.pt(ast))
    end
    
    
    local code = compiler:compile(ast)
    if debug == true then
        print("\ncode:")
        print(pt.pt(code))
    end

    
    local stack = {}
    local mem = { k0 = 0, k1 = 1, k10 = 10 }
    backend_build.run(code, mem, stack, 0)
    if debug == true then
        print("\nstack:")
        print(stack[1])
    end

    return stack[1]
end


run(params, debug)
