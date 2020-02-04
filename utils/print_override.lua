local Public = {}

local locale_string = {'', '[PRINT] ', nil}
local raw_print = print

function print(str)
    locale_string[3] = str
    log(locale_string)
end

Public.raw_print = raw_print

return Public
