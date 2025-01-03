local Event = require 'utils.event'
local Global = require 'utils.global'
local Inventory = require 'utils.inventory'
local Quality = require 'utils.quality'

local Public = {}

--[[
  Tracks all launched items per force in the global table.
  The structure looks like this:
  this = {
    [force_index] = {
      ['item_name'] = { normal = count1, uncommon = count2, count = total_count },
    },
  }
]]

local this = {}
Global.register(this, function(tbl) this = tbl end)

local function get_force_data(force_id)
  if type(force_id) == 'userdata' then
    force_id = force_id.index
  end
  this[force_id] = this[force_id] or {}
  return this[force_id]
end

-- Retrieve the contents of a rocket's cargo pod, optionally filtered
---@param rocket LuaEntity Represents the rocket entity
---@param filter? ItemFilter Optional filter for item selection
---@return ItemWithQualityCounts[] Array of items in the rocket
Public.get_rocket_contents = function(rocket, filter)
  if not (rocket and rocket.valid) then
    return {}
  end
  return Inventory.get_contents(rocket, filter)
end

-- Count the total items in a rocket's cargo pod, optionally filtered
---@param rocket LuaEntity Represents the rocket entity
---@param filter? ItemFilter Optional filter for item selection
---@return number The total item count in the rocket
Public.count_rocket_contents = function(rocket, filter)
  if not (rocket and rocket.valid) then
    return 0
  end
  return Inventory.get_item_count(rocket, filter)
end

--- Get the count of a specific item launched from a given force
--- @param options table Contains parameters: {name = string, force? = ForceID, quality? = string, comparator? = string}
--- @return number The number of items launched
Public.get_item_launched = function(options)
  local name = options.name
  local force_id = options.force or 'player'   -- Default to player if no force is specified
  local quality = options.quality or 'count'   -- Default to total count if no quality is specified
  local comparator = options.comparator or '=' -- Default to equal to if no comparator is specified

  local force = game.forces[force_id]
  if not (force and force.valid) then
    return 0
  end

  local item_info = get_force_data(force.index)[name]
  if item_info and quality ~= 'count' then
    local sum = 0
    for tier, _ in pairs(prototypes.quality) do
      if Quality.compare(tier, quality, comparator) then
        sum = sum + (item_info[tier] or 0)
      end
    end
    return sum
  end
  return (item_info and item_info[quality]) or 0
end

-- Event handler for when a rocket is launched; logs the items launched
-- Registered `on_rocket_launched` instead of `on_cargo_pod_finished_ascending` to allow other modules to rely on it
Event.add(defines.events.on_rocket_launched, function(event)
  local force = event.rocket and event.rocket.force
  if not force then
    return
  end

  local logs = get_force_data(force)
  for _, stack in pairs(Inventory.get_contents(event.rocket.cargo_pod)) do
    Inventory.merge_item_with_quality_counts(logs, stack)
    if _DEBUG then
      game.print(string.format('Launched: name = %s | quality = %s | count = %d', stack.name, stack.quality, stack.count))
    end
  end
end)

-- Event handler for resetting a force's logs
Event.add(defines.events.on_force_reset, function(event)
  this[event.force.index] = {}
end)

-- Event handler for merging logs from one force to another during force merging
Event.add(defines.events.on_forces_merging, function(event)
  local src = get_force_data(event.source)
  local dst = get_force_data(event.destination)

  for name, info in pairs(src) do
    dst[name] = dst[name] or {}
    for k, v in pairs(info) do
      dst[name][k] = (dst[name][k] or 0) + v
    end
  end

  this[event.source.index] = nil
end)

return Public
