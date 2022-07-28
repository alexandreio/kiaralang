local grammar = require "kiara.frontend.grammar"

local parser = {}

function parser.parse(input)
    return grammar.Grammar:match(input)
end

return parser
