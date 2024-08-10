local Event = require 'utils.event'
local Global = require 'utils.global'
local register_on_entity_destroyed = script.register_on_entity_destroyed

local Public = {}
local turrets_map = {}
local register_map = {}
local primitives = { index = nil }

Global.register(
  {
    turrets_map = turrets_map,
    register_map = register_map,
    primitives = primitives,
  },
  function(tbl)
    turrets_map = tbl.turrets_map
    register_map = tbl.register_map
    primitives = tbl.primitives
end)

function Public.register(entity, refill_name)
  if not (entity and entity.valid) then
    return
  end

  if not refill_name then
    return
  end

  local is_item = game.item_prototypes[refill_name] and true or false
  local is_fluid = game.fluid_prototypes[refill_name] and true or false

  if not (is_item or is_fluid )then
    return
  end

  local destroy_id = register_on_entity_destroyed(entity)
  local unit_id = entity.unit_number

  local data = {
    entity = entity,
    refill = refill_name,
    is_fluid = is_fluid,
    destroy_id = destroy_id
  }

  if data.is_fluid then
    data.capacity = data.entity.fluidbox.get_capacity(1)
  else
    data.item_stack = {
      name = data.refill,
      count = game.item_prototypes[data.refill].stack_size
    }
  end

  register_map[destroy_id] = unit_id
  turrets_map[unit_id] = data
end

function Public.remove(entity)
  local unit_id = entity.unit_number
  local destroy_id = turrets_map[unit_id].destroy_id

  register_map[destroy_id] = nil
  turrets_map[unit_id] = nil
end

function Public.reset()
  for k, _ in pairs(turrets_map) do
    turrets_map[k] = nil
  end
  for k, _ in pairs(register_map) do
    register_map[k] = nil
  end
end

local function on_entity_destroyed(event)
  local destroy_id = event.registration_number
  local unit_id = event.unit_number

  register_map[destroy_id] = nil
  turrets_map[unit_id] = nil
end
Event.add(defines.events.on_entity_destroyed, on_entity_destroyed)

local function on_tick()
  if primitives.index ~= nil and turrets_map[primitives.index] == nil then
    primitives.index = nil
    return
  end

  local idx, data = next(turrets_map, primitives.index)
  if not (data and data.entity and data.entity.valid) then
    primitives.index = nil
    return
  end

  if data.is_fluid then
    local fb = data.entity.fluidbox[1]
    fb.name = data.refill
    fb.amount = data.capacity
  else
    data.entity.insert(data.item_stack)
  end

  primitives.index = idx
end
Event.add(defines.events.on_tick, on_tick)

return Public
