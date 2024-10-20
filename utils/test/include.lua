local require = require
local pcall = pcall
local find = string.find

local function file_is_missing(message)
    return find(message, 'no such file') or find(message, 'File was removed to decrease save file size')
end

return function(name)
    local s, e = pcall(require, name)
    if not s and not file_is_missing(e) then
        error(e, 10)
    end
end
