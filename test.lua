
local pt = require("pt")
local parser = require("kiara.frontend.parser")
local compiler = require("kiara.backend.compiler")
local backend_build = require("kiara.backend.build")


local function run_code(input, debug)
    compiler:clean()

    if debug == true then
        print("input:", input)
        print("")
    end

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

local function assert_code(input, expected, debug)
    local result = run_code(input, debug)
    assert(result == expected)
end

local function assert_code_error(input, expected, debug)
    local _, err = pcall(run_code, input, debug)
    assert(string.match(err, expected) == expected)
end

local function assert_stat(input, expected, debug)
    local code = "function main() {\n return " .. input .. "\n}"
    assert_code(code, expected, debug)
end

-- Assert basic operations
assert_stat("1 + 1", 2)
assert_stat("1 - 1", 0)
assert_stat("2 * 2", 4)
assert_stat("2 / 2", 1)
assert_stat("1 + -1", 0)

-- FINAL PROJECT: Adding more operators - part 1

assert_stat("4 % 2", 0)
assert_stat("4 % 3", 1)
assert_stat("3 ^ 3", 27)
assert_stat("3 ^ 3 ^3", 7625597484987)

-- hexadecimal numbers
assert_stat("0x1", 1)
assert_stat("0xc0ffee", 12648430)
assert_stat("0Xc0ffee", 12648430)

-- FINAL PROJECT: Adding more operators - part 2
assert_stat("-1", -1)
assert_stat("- -1", 1)
assert_stat("-(1+2)", -3)

assert_stat("(1 < 2)", 1)
assert_stat("(1 > 2)", 0)
assert_stat("(1 >= 1)", 1)
assert_stat("(1 >= 0)", 1)
assert_stat("(1 >= 3)", 0)

assert_stat("(1 <= 2)", 1)
assert_stat("(2 <= 2)", 1)
assert_stat("(5 <= 2)", 0)
assert_stat("(1 == 1)", 1)
assert_stat("(1 == 2)", 0)
assert_stat("(1 != 2)", 1)
assert_stat("(1 != 1)", 0)


-- Floating-point numbers
assert_stat("1.5", 1.5)
assert_stat("-1.5", -1.5)
assert_stat("0.1", 0.1)
assert_stat(".1", 0.1)
assert_stat(".5", 0.5)

-- scientific notation
assert_stat("0.5E-3", 0.0005)
assert_stat("0.5e-3", 0.0005)
assert_stat(".5e-3", 0.0005)
assert_stat("10e3", 10000.0)
assert_stat("10E3", 10000.0)


-- Rules for Identifiers
assert_code([[
    function main() {
        var a_b = 2;
        return a_b
    }
]], 2)

assert_code([[
    function main() {
        var two_gt_one? = (2 > 1);
        return two_gt_one?
    }
]], 1)

-- FINAL PROJECT: Empty Statement
assert_code([[
    function main() {
        {};
        ;;;;
        return 0
    }
]], 0)


-- FINAL PROJECT:  Print Statement
assert_code([[
    function main() {
        @ (2);
        return 0
    }
]], 0)


assert_code_error([[
    function main() {
        var a = b + 1;
    }
]], "variable b is not defined")

-- FINAL PROJECT: Error messages with line numbers
assert_code_error([[
    function main() {
        @ (2)
        return 0
    }
]], "syntax error on line: 5 col: 33")


-- FINAL PROJECT: Block comments
assert_code([[
    function main() {
        #{
            this is a 
            block comment
        #}
        var a = 1;
        return a
    }
]], 1)

-- FINAL PROJECT: ‘not’ operator
assert_stat("!(1 > 2)", 1)
assert_stat("!!(1 > 2)", 0)

-- FINAL PROJECT: ‘elseif’
assert_code([[
    function main() {
        if 0 {return  1} else {return 2}
    }
]], 2)

assert_code([[
    function main() {
        var a = 3;
        var b = 0;
        if (a > 4) { b = 5 }
        elseif (a == 2) {b = 200000000}
        elseif (a == 3) {b = 300000000}
        else { b = 10 };

        return b
    }
]], 300000000)

