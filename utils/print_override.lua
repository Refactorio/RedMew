local Public = {}

local tostring = tostring

local raw_print = print
function print(str)
    raw_print('[PRINT] ' .. tostring(str))
end

Public.raw_print = raw_print

return Public
