
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

    -- print(input)
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
    local mem = { k0 = 0, k1 = 1, k11 = 10 }
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

assert_code([[
    function main() {
        var a = 2;
        var b = 0;
        if (a > 4) { b = 5 }
        elseif (a == 2) {b = 200000000}
        elseif (a == 3) {b = 300000000}
        else { b = 10 };

        return b
    }
]], 200000000)

assert_code([[
    function main() {
        var a = 1;
        var b = 0;
        if (a > 4) { b = 5 }
        elseif (a == 2) {b = 200000000}
        elseif (a == 3) {b = 300000000}
        else { b = 10 };

        return b
    }
]], 10)


-- arrays
assert_code([[
    function main() {
        var a = new[10];
        a[5] = 50;

        return a[5]
    }
]], 50)

-- FINAL PROJECT: print arrays
assert_code([[
    function main() {
        var a = new[10];
        a[5] = 50;
        a[2] = 1;

        @ (a);

        return a[5] + a[2]
    }
]], 51)


--  Name Conflicts Among Functions
assert_code_error([[
    function foo() {
        return 1
    }

    function foo() {
        return 2
    }

    function main() {
        return foo()
    }
]], "function 'foo' already declared")


--  Optional initialization for local variables
assert_code([[
    function main () {
        var foo;
        return foo
    }
]], 0)

assert_code([[
    function main () {
        var foo;
        foo = 42;
        return foo
    }
]], 42)

--  Checking redeclaration of variables
assert_code([[
    function foo() {
        var bar = 11;
        return bar;
    }


    function main () {
        return foo()
    }
]], 11)


assert_code_error([[
    function foo() {
        var bar = 10;
        var bar = 11;
    }


    function main () {
        return foo()
    }
]], "local variable: bar already declared locally")


-- Checking redeclaration of variables and parameters
assert_code([[
    function foo(bar) {
        return bar;
    }


    function main () {
        return foo(15)
    }
]], 15)


assert_code_error([[
    function foo(bar, bar) {
        return bar;
    }


    function main () {
        return foo(15, 16)
    }
]], "param bar already declared")


-- Check for Main
assert_code([[
    function main () {
        var foo = 42;
        return foo
    }
]], 42)


assert_code_error([[
    function main (bar) {
        var foo = 42;
        return foo
    }
]], "main function must have no parameters")


-- Adding checks to the interpreter
assert_code([[
    function main () {
        var a = new[10];
        a[10] = 9;
        return a[10]
    }
]], 9)


assert_code_error([[
    function main () {
        var a = new[10];
        a[11] = 9;
        return a[11]
    }
]], "index out of range. max array size: 10")


-- FINAL PROJECT: Logical operators
--  and
assert_stat("1 and 0", 0)
assert_stat("0 and 1", 1)
assert_stat("5 and 10", 10)
assert_stat("10 and 5", 5)
assert_stat("10 and 10", 10)
--  or
assert_stat("1 or 0", 1)
assert_stat("0 or 1", 1)
assert_stat("5 or 10", 5)
assert_stat("10 or 5", 10)
assert_stat("10 or 10", 10)

-- while test
assert_code([[
    function main() {
        var n = 0;
        var i = 0;

        while (i < 10) {
            n = n + 1;
            i = i + 1;
        };

        return n;
    }
]], 10)

-- wrong number of arguments
assert_code([[
    function foo(bar) {
        return bar + 1;
    }

    function main () {
        return foo(5);
    }
]], 6)

assert_code_error([[
    function foo(bar) {
        return bar + 1;
    }

    function main () {
        return foo(5, 6);
    }
]], "wrong number of arguments to foo")


-- FINAL PROJECT: Forward Declarations
assert_code([[
    function odd();

    function odd() {
        return 2;
    }

    function even () {
        var n = 5;
        if n {
            return odd()
        } else {
            return 1
        }
    }


    function main () {
        var n = 10;
        return even()
    }

]], 2)

assert_code_error([[
    function odd();

    function even () {
        var n = 5;
        if n {
            return odd()
        } else {
            return 1
        }
    }


    function main () {
        var n = 10;
        return even()
    }

]], "function: odd not declared")


assert_code_error([[
    function odd();

    function odd() {
        return 2;
    }

    function odd() {
        return 5;
    }

    function even () {
        var n = 5;
        if n {
            return odd()
        } else {
            return 1
        }
    }


    function main () {
        var n = 10;
        return even()
    }

]], "function 'odd' already declared")

-- test recursion
assert_code([[
    function fact(n) {
        if n {
            return n * fact(n - 1)
        } else {
            return 1
        }
    }

    function main () {
        return fact(6)
    }

]], 720)

assert_code([[
    function foo(a, b, c=20) {
        return c
    }

    function main () {
        return foo(1, 0)
    }
]], 20)


-- FINAL PROJECT: Default Arguments
assert_code([[
    function fa(b, a=2) {
        return a;
    }

    function ab(a, b) {
        var res = fa(0) + 5;
        return res;
    }

    function main () {
        return ab(0, 0);
    }

]], 7)


assert_code([[
    function fa(b, a=2) {
        return a;
    }

    function ab(a, b) {
        var res = fa(0, b) + 5;
        return res;
    }

    function main () {
        return ab(0, 5);
    }

]], 10)

assert_code([[
    function foo(a) {
        return a + 1;
    }

    function bar(b) {
        return b + 1;
    }

    function main () {
        return foo(bar(1));
    }

]], 3)

-- assert_stat("1 and 0", 0)

-- FINAL PROJECT: Multidimensional new
-- assert_code([[
--     function main() {
--         var d = new[3][5][2];

--         d[2][1][1] = 6000;
--         d[3][1][1] = 4000;
--         @ (d[2][1][1]);
--         @ (d[3][1][1]);


--         return d[2][1][1]

--     }
-- ]], 6000, true)

