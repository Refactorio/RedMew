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
