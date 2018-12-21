local pairs = pairs

--- Checks if a table contains an element
-- @param t table to search
-- @param e element to search for
-- @returns the index of an element or -1
table.index_of = function(t, e)
    local i = 1
    for _, v in pairs(t) do
        if v == e then
            return i
        end
        i = i + 1
    end
    return -1
end

local index_of = table.index_of

--- Checks if a table contains an element
-- @param t table to search
-- @param e element to search for
-- @returns true or false
table.contains = function(t, e)
    return index_of(t, e) > -1
end
