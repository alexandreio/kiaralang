local lpeg = require "lpeg"

function I(msg)
    return lpeg.P(function() print(msg); return true end)
end
