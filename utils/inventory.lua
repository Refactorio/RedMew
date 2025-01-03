local Quality = require 'utils.quality'

local Public = {}

local function match_filter(stack, filter)
  if filter == nil then
    return true
  end

  if type(filter) == 'string' then
    filter = { name = filter }
  end

  return (not filter.name or filter.name == stack.name) and
         (not filter.quality or Quality.compare(stack.quality, filter.quality, filter.comparator or '='))
end

local function get_inventory_contents(inventory, filter)
  local res = {}
  if inventory and inventory.valid then
    for _, stack in pairs(inventory.get_contents()) do
      if match_filter(stack, filter) then
        res[#res + 1] = stack
      end
    end
  end
  return res
end

local function get_entity_contents(entity, filter)
  local res = {}
  local inv = entity.get_inventory
  for k = 1, entity.get_max_inventory_index() do
    for _, stack in pairs(get_inventory_contents(inv(k), filter)) do
      res[#res + 1] = stack
    end
  end
  return res
end

-- Merge item with quality counts into the specified table
---@param tbl table
---@param stack ItemWithQualityCounts
Public.merge_item_with_quality_counts = function(tbl, stack)
  if type(stack) == 'string' then
    stack = { name = stack, count = 1 }
  end

  local data = tbl[stack.name] or { count = 0 }
  tbl[stack.name] = data

  data.count = data.count + stack.count
  data[stack.quality] = (data[stack.quality] or 0) + stack.count
end

-- Converts the specified contents into a dictionary based on the optional filter
---@param contents ItemWithQualityCounts[]
---@param filter? ItemFilter
---@return table<string, table><string, number>
Public.to_dictionary = function(contents, filter)
  local res = {}
  for _, stack in pairs(contents) do
    if match_filter(stack, filter) then
      Public.merge_item_with_quality_counts(res, stack)
    end
  end
  return res
end

-- Retrieves contents from a LuaEntity or LuaInventory based on options
---@param LuaObject LuaEntity|LuaInventory
---@param filter? ItemFilter
---@return ItemWithQualityCounts[]
Public.get_contents = function(LuaObject, filter)
  if LuaObject and LuaObject.valid then
    if LuaObject.object_name == 'LuaEntity' then
      return get_entity_contents(LuaObject, filter)
    elseif LuaObject.object_name == 'LuaInventory' then
      return get_inventory_contents(LuaObject, filter)
    end
  end
  return {}
end

-- Counts the total items based on a filter
---@param LuaObject LuaEntity|LuaInventory
---@param filter? ItemFilter
---@return number
Public.get_item_count = function(LuaObject, filter)
  local res = 0
  for _, stack in pairs(Public.get_contents(LuaObject, filter)) do
    res = res + stack.count
  end
  return res
end

-- Returns a dictionary of item counts from the specified LuaObject
---@param LuaObject LuaEntity|LuaInventory
---@param filter? ItemFilter
---@return table<string, table><string, number>
Public.get_contents_dictionary = function(LuaObject, filter)
  return Public.to_dictionary(Public.get_contents(LuaObject, filter))
end

return Public
