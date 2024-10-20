local Public = {}

---@param item_stack LuaItemStack|SignalFilter
---@return SignalFilter
local function parse_item_stack(item_stack)
  return {
    value = {
      type = item_stack.type or 'item',
      name = item_stack.name,
      quality = item_stack.quality,
      comparator = item_stack.comparator,
    },
    min = item_stack.min or item_stack.count,
    max = item_stack.max or item_stack.count,
    minimum_delivery_count = item_stack.minimum_delivery_count,
    import_from = item_stack.import_from,
  }
end
Public.parse_item_stack = parse_item_stack

---@param logistic_point LuaLogisticPoint
---@return table<SignalFilter>
Public.get_filters = function(logistic_point)
  local filters = {}
  for _, section in pairs(logistic_point.sections) do
    for _, filter in pairs(section.filters) do
      if filter.value and filter.value.name then
        filters[#filters + 1] = filter
      end
    end
  end
  return filters
end

---@param logistic_point LuaLogisticPoint
---@param filters table<LuaItemStack|SignalFilter>
Public.add_filters = function(logistic_point, filters)
  local section = logistic_point.add_section()
  for index, filter in pairs(filters) do
    section.set_slot(parse_item_stack(filter), index)
  end
end

---@param logistic_point LuaLogisticPoint
---@param filters table<LuaItemStack|SignalFilter>
Public.remove_filters = function(logistic_point, filters)
  for _, to_remove in pairs(filters) do
    to_remove = parse_item_stack(to_remove)
    for _, section in pairs(logistic_point.sections) do
      for slot_index, filter in pairs(section.filters) do
        if filter.value.name == to_remove.name then
          if to_remove.quality and filter.quality then
            if to_remove.quality == filter.quality then
              section.clear_slot(slot_index)
            end
          else
            section.clear_slot(slot_index)
          end
        end
      end
    end
  end
end

---@param logistic_point LuaLogisticPoint
Public.clear_sections = function(logistic_point)
  for i = 1, logistic_point.sections_count do
    logistic_point.remove_section(i)
  end
end

return Public
