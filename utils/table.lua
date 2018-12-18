local random = math.random
local floor = math.floor
local remove = table.remove
local insert = table.insert
local tonumber = tonumber
local pairs = pairs
local table_size = table_size

--- Searches a table to remove a specific element without an index
-- @param t table to search
-- @param element to search for
table.remove_element = function(t, element)
    for k, v in pairs(t) do
        if v == element then
            remove(t, k)
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
            insert(t1, v)
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

local index_of = table.index_of

--- Checks if a table contains an element
-- @param t table to search
-- @param e element to search for
-- @returns true or false
table.contains = function(t, e)
    return index_of(t, e) > -1
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
-- because this uses math.random, it cannot be used outside of events
-- @param t table to select an element from
-- @param sorted boolean to indicate whether the table is sorted by numerical index or not
-- @param key boolean to indicate whether to return the key or value
-- @return a random element of table t
table.get_random = function(t, sorted, key)
    if sorted then
        return t[random(#t)]
    end
    local target_index = random(1, table_size(t))
    local count = 1
    for k, v in pairs(t) do
        if target_index == count then
            if key then
                return k
            else
                return t[v]
            end
        end
        count = count + 1
    end
end

--- Chooses a random entry from a weighted table
-- because this uses math.random, it cannot be used outside of events
-- @param weight_table table of tables with items and their weights
-- @param item_index number of the index of items, defaults to 1
-- @param weight_index number of the index of the weights, defaults to 2
-- @returns a table entry
-- @see features.chat_triggers::hodor
table.get_random_weighted = function(weighted_table, item_index, weight_index)
    local total_weight = 0
    item_index = item_index or 1
    weight_index = weight_index or 2

    for _, w in pairs(weighted_table) do
        total_weight = total_weight + w[weight_index]
    end

    local index = random() * total_weight
    local weight_sum = 0
    for _, w in pairs(weighted_table) do
        weight_sum = weight_sum + w[weight_index]
        if weight_sum >= index then
            return w[item_index]
        end
    end
end

--- Creates a fisher-yates shuffle of a sequential number-indexed table
-- because this uses math.random, it cannot be used outside of events if no rng is supplied
-- from: http://www.sdknews.com/cross-platform/corona/tutorial-how-to-shuffle-table-items
-- @param t table to shuffle
table.shuffle_table = function(t, rng)
    local rand = rng or math.random
    local iterations = #t
    if iterations == 0 then
        error('Not a sequential table')
        return
    end
    local j

    for i = iterations, 2, -1 do
        j = rand(i)
        t[i], t[j] = t[j], t[i]
    end
end

--- Clears all existing entries in a table
-- @param t table to clear
table.clear_table = function(t)
    for i in pairs(t) do
        t[i] = nil
    end
end

--[[
  Returns the index where t[index] == target.
  If there is no such index, returns a negative value such that bit32.bnot(value) is
  the index that the value should be inserted to keep the list ordered.
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
table.binary_search = function(t, target)
    --For some reason bit32.bnot doesn't return negative numbers so I'm using ~x = -1 - x instead.

    local lower = 1
    local upper = #t

    if upper == 0 then
        return -2 -- ~1
    end

    repeat
        local mid = floor((lower + upper) * 0.5)
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

-- add table-related functions that exist in base factorio to the 'table' table
table.inspect = require 'inspect'
table.size = table_size
