local require = require
local pcall = pcall

return function(name)
    local s, e = pcall(require, name)
    if not s and not string.find(e, 'no such file') then
        error(e, 2)
    end
end
