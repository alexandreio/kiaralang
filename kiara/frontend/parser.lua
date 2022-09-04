local grammar = require "kiara.frontend.grammar"

local parser = {}

local function syntaxError(input, max)
    local line = 1
    local col = 1

    for i = 1, max do
        if input:sub(i,i) == "\n" then
            line = line + 1
            col = 1
        else
            col = col + 1
        end
    end

    error("syntax error on line: " .. line .. " col: " .. col)
end

function parser.parse(input)
    local result = grammar.Grammar:match(input)
    if (not result) then
        syntaxError(input, grammar.maxmatch)
        os.exit(1)
    end
    return result
end

return parser
