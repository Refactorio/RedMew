local function assert_argument_valid(a, arg_type)
  arg_type = arg_type or "table"
  if type(a) ~= arg_type then
    error("bad argument #1 to '" .. debug.getinfo(2, "n").name .. "' (table expected, got ".. type(a) .. ")", 3)
  end
end

table.remove_element = function(t, element)
  assert_argument_valid(t)
  for k,v in pairs(t) do
    if v == element then
      table.remove(t, k)
      break
    end
  end
end

table.add_all = function (t1, t2)
  assert_argument_valid(t1)
  assert_argument_valid(t2)
  for k,v in pairs(t2) do
    if tonumber(k) then
      table.insert(t1, v)
    else
      t1[k] = v
    end
  end
end

table.size = function(t)
  assert_argument_valid(t)
  local size = 0
  for _,_ in pairs(t) do size = size + 1 end
  return size
end

table.index_of = function(t, e)
  assert_argument_valid(t)
  local i = 1
  for _,v in pairs(t) do
    if v == e then
      return i
    end
    i = i + 1
  end
  return -1
end

table.contains = function(t, e)
  assert_argument_valid(t)
  return table.index_of(t, e) > -1
end

table.set = function (t, index, element)
  assert_argument_valid(t)
  assert_argument_valid(index, "number")
  local i = 1
  for k,v in pairs(t) do
    if i == index then
      t[k] = element
      return nil
    end
    i = i + 1
  end
  error("Index out of bounds", 2)
end

table.get = function (t, index)
  assert_argument_valid(t)
  assert_argument_valid(index, "number")
  local i = 1
  for k,v in pairs(t) do
    if i == index then
      return t[k]
    end
    i = i + 1
  end
  error("Index out of bounds", 2)
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
table.binary_search = function(t, target)
  --For some reason bit32.bnot doesn't return negative numbers so I'm using ~x = -1 - x instead.
    assert_argument_valid(t)
    assert_argument_valid(target, "number")
  
    local lower = 1
    local upper = #t
    
    if upper == 0 then
      return -2 -- ~1
    end
  
    repeat 
      local mid = math.floor( (lower + upper) / 2 )
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
