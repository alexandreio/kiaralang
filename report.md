# Kiara
Author: Alexandre Ferreira

## 1 - Introduction
Kiara is a language implemented on top of Lua. Kiara generates a bytecode for a valid program and
runs it in a stack machine. All memory management is handled it by Lua at this point.

Kiara still is a simple language, it doesn't support strings or modules. All program must be contained in a simple file with an extension .kiara.

For a code by valid, it **must** contain a `main` function without any argument. This is our start point.


## 2 - Basic Concepts
Kiara is a simple language aimed to worked with numbers at this number. Unfortunately, it doesn't support strings at this point.

The current types supported are: _number_, _functions_ and _nil_ inherits by Lua in some cases.
There isn't a boolean type. Kiara uses **0** as **false** and anything different than **0** as **true**.

The types of numbers notations that Kiara supports are: **integer**, **float**, **hexadecimal** and **scientific notation**. **hexadecimals** numbers are converted to **integers** and **scientific notation numbers** are converted to **float**.

Kiara also support **functions**. Functions can have arguments and one default argument in the end if it has at least one non-default argument.

## 2.1 - Error messages with line numbers
Don't worry with commit any mistake while writing a Kiara program.
If there is a syntax error inside or program, you will receive a syntax error with the line and column of the error.

## 3 - The Language

### 3.1 - Lpeg
Kiara has as parser the LPeg. LPegis a pattern-matching library for Lua based on PEG.

### 3.2 - Reserved words
Kiara have the following reserved words: **return**, **if**, **elseif**, **else**, **while**, **new**, **function**, **var**, **and** and **or**.


### 3.3 - Functions

A Kiara program must have a function called `main`
```
function main () {
}

```

### 3.4 - Defining Functions

We can create a function that sums two numbers as the following:

```
function add(a, b) {
    return a + b;
}

function main () {
    return add(1, 2);
}
```
A function in Kiara is defined by the keyword `function` followed by its name with. If a function doesn't accept any argument it should have `()`, if arguments they should be inside the `()` and separated by a comma.
The content of a function must be inside a statement. A statement stars with a `{` and it ends with a `}`

If you prefer, you can write only the header of a `function` and after the body. **The functions with body must be defined before the main function**

```
function add(a, b);
function sub(a, b);

function add(a, b) {
    return a + b;
}
function sub(a, b) {
    return a - b;
}

function main () {
    return add(1, 2);
}
```

If a function have at least one argument you can have one optional argument.

```
function magical(a, b, c=20) {
    return a + b + 20;
}

function main () {
    return magical(1, 2);
}
```

### 3.5 - Comments

Kiara supports single line comments with `#` and multiple line comments.
A multiple line comment starts with `#{` and finish it with `#}`.

```
function add(a, b) {
    # sums two numbers
    return a + b;
}

function main () {
    #{
        this is a dummy program.
        add will always sum 1 and 2.
    #}
    return add(1, 2);
}
```
### 3.6 - Operators
Kiara have the following operators:
- `+`: Sums two expressions
- `-`: Subract two expressions
- `*`: Multiple two expressions
- `\`: Divide two expressions
- `^`: Exponential operator
- `%`: remainder operator
- `<`: Less than
- `>`: Greater than
- `>=`: Greater or equal
- `<=`: Less or equal
- `==`: Equal
- `!=`: Not Equal
- `and`: And operator
- `or`: Or operator
- `!` Not operator

The result for `<`, `>`, `>=`, `<=`, `==`, `!=` will be **1 if true** or **0 if false**.

The logical operators `and` and `or` are implemented as short circuits. The second operand is evaluated
only when needed. For 'and', the second operand is evaluated only when the first results in true. For 'or', the second operand is evaluated only when the first results in false.

The `!` (not operator) will invert the value of a boolean

You can found test cases for each operator in the `test.lua`

### 3.7 - Statements
Kiara supports statements similar to other conventional languages.

#### 3.7.1 - Blocks
A block is a list of statements:

Lpeg:<br>
`Block = T "{" * Stats * T ";" ^ -1 * T "}"`

Kiara has empty statements. A program can have extra `;` or `{}`.


### 3.7.2 - Variables and Assignment
You declare variables as well.

`var hello = 1;`

To declare a variable you must to use the keyword `var` followed by it name and it content.
A variable name can have letters, numbers, _ and ?.

Kiara support simple assignments only.

### 3.7.3 - Control Structures
Kiara have **if** and **while** as control structures.

An if can have elseif statement and else statement for a default case.
```
function main() {
    var n = 4;

    if (n < 5) {
        return  1;
    } elseif (n == 6) {
        return 6;
    }else {
        return 0;
    }
}
```
The **while** it's the only repetition control struct that Kiara have.
```
function main() {
    var n = 0;
    var i = 0;

    while (i < 10) {
        n = n + 1;
        i = i + 1;
    };

    return n;
}
```
In Kiara a **while** __**must**__ finish with `;`.

### 3.8 - Arrays
Kiara have support for arrays of one or more dimensional.
```
function main() {
    var a = new[10];
    a[5] = 50;
}
```
In the example above we are creating an array of one dimension with 10 elements.
and we are assigning the value 50 at position 5;

```
function main() {
    var a = new[2][2];
    a[1][1] = 1;
    a[1][2] = 0;
}
```
In the example above we are creating an array of two dimension with 2 elements.

**Kiara language doesn't support at this point return a value for a multidimensional array. It can return a value only from arrays with one dimension**

### 3.9 - Print Statement
You can print almost any statement in Kiara.
To print a statement you need to write `@ statement`;
```
function main() {
    @ 1 + 1;
    @ (1 > 0);

    var a = new[10];
    a[5] = 50;
    @ a;
    @ a[5];
}
```
Is posstible to print expressions, arrays with one dimension and the value of an array postion.