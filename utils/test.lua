--- Searches a table to remove a specific element without an index
-- @param t table to search
-- @param element to search for
remove_element = function(t, element)
    for k, v in pairs(t) do
        if v == element then
            remove(t, k)
            break
        end
    end
end
