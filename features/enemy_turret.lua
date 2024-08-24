local Event = require 'utils.event'
local Global = require 'utils.global'
local Task = require 'utils.task'
local Token = require 'utils.token'
local register_on_entity_destroyed = script.register_on_entity_destroyed

local Public = {}
local turrets_map = {}
local register_map = {}
local primitives = { index = nil }
local Artillery = {
  enabled = true,
  turret_name = 'artillery-turret',
  character_projectile = 'artillery-projectile',
  structure_projectile = 'rocket',
  target_force = 'player',
  last_fire = 0,
  fire_interval = 60, -- ticks
  cooldown = 480, -- ticks
  min_range = 32, -- tiles
  max_range = 224, -- tiles
  max_targeting_attempts = 10,
  range_modifier = nil,
  manual_range_modifier = nil,
  creation_distance = 1.6,
  target_offset = { -0.15625, -0.07812 },
  target_entities = {
    'artillery-turret',
    'artillery-wagon',
    'car',
    'cargo-wagon',
    'character',
    'flamethrower-turret',
    'fluid-wagon',
    'furnace',
    'gun-turret',
    'lab',
    'laser-turret',
    'locomotive',
    'radar',
    'silo',
    'spidertron',
    'tank',
  },
}

Global.register(
  {
    turrets_map = turrets_map,
    register_map = register_map,
    primitives = primitives,
    artillery = Artillery,
  },
  function(tbl)
    turrets_map = tbl.turrets_map
    register_map = tbl.register_map
    primitives = tbl.primitives
    Artillery = tbl.artillery
end)

local function distance(posA, posB)
  return math.sqrt((posA.x - posB.x)^2 + (posA.y - posB.y)^2)
end

function Public.get_artillery_settings()
  return Artillery
end

function Public.set_artillery_settings(key, value)
  Artillery[key] = value
end

function Public.register(entity, refill_name)
  if not (entity and entity.valid) then
    return
  end

  if not refill_name then
    return
  end

  local is_item = game.item_prototypes[refill_name] and true or false
  local is_fluid = game.fluid_prototypes[refill_name] and true or false
  local is_artillery = entity.prototype.type == Artillery.turret_name

  if not (is_item or is_fluid or is_artillery) then
    return
  end

  local destroy_id = register_on_entity_destroyed(entity)
  local unit_id = entity.unit_number

  local data = {
    entity = entity,
    refill = refill_name,
    is_fluid = is_fluid,
    is_artillery = is_artillery,
    destroy_id = destroy_id
  }

  if data.is_artillery then
    data.next_fire = game.tick
  end
  if data.is_fluid then
    data.fluid_stack = {
      name = data.refill,
      amount = data.entity.fluidbox.get_capacity(1) or 100
    }
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

local artillery_projectile_token = Token.register(function(data)
  local surface = game.get_surface(data.surface_index)
  local target = data.target
  local source = data.source
  if not (surface and surface.valid) then return end
  if not (target and target.valid) then return end
  if not (source and source.valid) then return end
  surface.create_entity{
    name = data.name,
    position = data.position,
    target = target,
    source = source,
    force = 'enemy',
    speed = 1.5,
  }
end)

local function simulate_automatic_artillery(data)
  if data.next_fire > game.tick then
    return
  end

  local entity = data.entity
  local surface = entity.surface
  local source_position = entity.position
  local range_modifier = Artillery.range_modifier or entity.force.artillery_range_modifier or 0
  local manual_range_modifier = Artillery.manual_range_modifier or entity.prototype.manual_range_modifier or 0
  local params = {
    position = source_position,
    radius = Artillery.max_range * (1 + range_modifier) * (1 + manual_range_modifier),
    name = Artillery.target_entities,
    force = Artillery.target_force,
    limit = Artillery.max_targeting_attempts,
  }
  local targets = surface.find_entities_filtered(params)

  if #targets == 0 then
    return
  end

  for i = 1, #targets do
    local target = targets[i]
    if distance(source_position, target.position) > Artillery.min_range then
      Task.set_timeout_in_ticks(Artillery.fire_interval, artillery_projectile_token, {
        surface_index = surface.index,
        name = target.name == 'character' and Artillery.character_projectile or Artillery.structure_projectile,
        position = target.position,
        target = target,
        source = entity,
        force = 'enemy',
        speed = 1.5,
      })
      data.next_fire = game.tick + Artillery.cooldown
      Artillery.last_fire = game.tick
      break
    end
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

  if Artillery.enabled and data.is_artillery and ((Artillery.last_fire + Artillery.fire_interval) < game.tick) then
    simulate_automatic_artillery(data)
  end
  if data.is_fluid then
    data.entity.insert_fluid(data.fluid_stack)
  else
    data.entity.insert(data.item_stack)
  end

  primitives.index = idx
end
Event.add(defines.events.on_tick, on_tick)

return Public
