# KiaraLang

## About the project

Kiara is a simple language created for [Building a Programming Language](https://classpert.com/classpertx/courses/building-a-programming-language/cohort) course.


## Getting Started

### Prerequisites
 - Lua 5.3
 - Luarocks
 - LPeg `luarocks install lpeg`

### Struct
├── kiara
│   ├── backend
│   │   ├── build.lua
│   │   └──compiler.lua
│   ├── frontend
│   │   ├── debug.lua
│   │   ├── grammar.lua
│   │   └── parser.lua
├── interpreter.lua
└── test.lua

- [kiara\interpreter.lua](kiara\interpreter.lua): The start point of the language. By default it will print the AST and the code for the program that you pass. If you want to not display those info you need to edit `run(params, true)` to `run(params, false)`
- [kiara\parser.lua](kiara\parser.lua): Responsible to parser the output of the `kiara\grammar.lua`
- [kiara\debug.lua](kiara\debug.lua): A helper function to help us to debug the `kiara\grammar.lua`
- [kiara\grammar.lua](kiara\grammar.lua): The LPeg  grammar for KiaraLang.
- [kiara\compiler.lua](kiara\compiler.lua): Generate the bytecode for the stack machine.
- [kiara\build.lua](kiara\build.lua): The language stack machine.


### Usage

First read the [Report](report.md) to understand the language.

To run a .kiara program you need to run the following command:

`lua kiara/interpreter.lua example.kiara`

where `example.kiara` is the file that we want to run.

### Tests
Exists a test for every functionally of the language in the file [test.lua](test.lua)
You can run the tests using the following commands:

`lua test.lua` or `make tests`

## Roadmap
- [ ] Fix multidimensional arrays
- [ ] Implement support for strings