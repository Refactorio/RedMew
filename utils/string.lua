--luacheck: globals string

--- Removes whitespace from the start and end of the string.
-- http://lua-users.org/wiki/StringTrim
function string.trim(str)
    return (str:gsub("^%s*(.-)%s*$", "%1"))
end

return string
