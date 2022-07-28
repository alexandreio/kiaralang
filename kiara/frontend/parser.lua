local grammar = require "kiara.frontend.grammar"

local parser = {}

local function syntaxError(input, max)
    print("syntax error:")
    print("line: " .. grammar.currentline)
    -- print("col: " .. (grammar.maxmatch / grammar.currentline) + 1)
    print(grammar.maxmatch)
    print(string.sub(input, max - 10, max - 1) .. " ^^^ " .. string.sub(input, max, max + 11))
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
