--- Searches a table to remove a specific element without an index
-- @param t table to search
-- @param element to search for
table.remove_element = function(t, element)
    for k, v in pairs(t) do
        if v == element then
            table.remove(t, k)
            break
        end
    end
end

--- Adds the contents of table t2 to table t1
-- @param t1 table to insert into
-- @param t2 table to insert from
table.add_all = function(t1, t2)
    for k, v in pairs(t2) do
        if tonumber(k) then
            table.insert(t1, v)
        else
            t1[k] = v
        end
    end
end

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

--- Checks if a table contains an element
-- @param t table to search
-- @param e element to search for
-- @returns true or false
table.contains = function(t, e)
    return table.index_of(t, e) > -1
end

--- Adds an element into a specific index position while shuffling the rest down
-- @param t table to add into
-- @param index the position in the table to add to
-- @param element to add
table.set = function(t, index, element)
    local i = 1
    for k in pairs(t) do
        if i == index then
            t[k] = element
            return nil
        end
        i = i + 1
    end
    error('Index out of bounds', 2)
end

--- Chooses a random entry from a table
--@param t table to select an element from
--@param sorted boolean to indicate whether the table is sorted by numerical index or not
--@return a random element of table t
table.get_random = function(t, sorted)
    if sorted then
        return t[math.random(#t)]
    else
        local target_index = math.random(1, table_size(t))
        local count = 1
        for _, v in pairs(t) do
            if target_index == count then
                return t[v]
            end
        end
    end
end

--- Chooses a random entry from a weighted table
-- @param weight_table a table of tables with items and their weights
-- @param item_index the index of the items
-- @param weight_index the index of the weights
-- @returns a random item with weighting
-- @see features.chat_triggers.hodor
table.get_random_weighted = function(weighted_table, item_index, weight_index)
    local total_weight = 0

    for _, w in pairs(weighted_table) do
        total_weight = total_weight + w[weight_index]
    end

    local index = math.random(total_weight)
    local weight_sum = 0
    for _, w in pairs(weighted_table) do
        weight_sum = weight_sum + w[weight_index]
        if weight_sum >= index then
            return w[item_index]
        end
    end
end

--[[
  Returns the index where t[index] == target.
  If there is no such index, returns a negative vaule such that bit32.bnot(value) is
  the index that the vaule should be inserted to keep the list ordered.
  t must be a list in ascending order for the return value to be valid.

  Usage example:
  local t = {1,3,5,7,9}
  local x = 5
  local index = table.binary_search(t, x)
  if index < 0 then
    game.print("value not found, smallest index where t[index] > x is: " .. bit32.bnot(index))
  else
    game.print("value found at index: " .. index)
  end
]]
table.binary_search =
    function(t, target)
    --For some reason bit32.bnot doesn't return negative numbers so I'm using ~x = -1 - x instead.

    local lower = 1
    local upper = #t

    if upper == 0 then
        return -2 -- ~1
    end

    repeat
        local mid = math.floor((lower + upper) / 2)
        local value = t[mid]
        if value == target then
            return mid
        elseif value < target then
            lower = mid + 1
        else
            upper = mid - 1
        end
    until lower > upper

    return -1 - lower -- ~lower
end
