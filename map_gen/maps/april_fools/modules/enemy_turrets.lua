-- turrets have a 90% chance of being on player force when placed
-- Be sure to adjust ammo count/amount on the enemy turrets below as needed
-- Completed

local Global = require 'utils.global'

local BASE_PERCENT = 0.05
local MAX_RAND = 100
local LASER_SHOTS_PER_LEVEL = 10 -- No idea what a good number is here balance wise.
local ENERGY_PER_SHOT = 800000 -- 1 shot of the laser turret

local _global = { level = 0, max_level = 10 }

Global.register(_global, function(tbl)
  _global = tbl
end)

-- ============================================================================

local TURRET_ACTIONS = {
  ['gun-turret'] = function(entity)
    entity.insert{ name = 'firearm-magazine', count = 2 * (_global.level or 1) }
  end,
  ['flamethrower-turret'] = function(entity)
    entity.insert_fluid{ name = 'crude-oil', amount = 6 * (_global.level or 1) }
  end,
  ['artillery-turret'] = function(entity)
    entity.insert{ name = 'artillery-shell', count = _global.level or 1 }
  end,
  ['laser-turret'] = function(entity)
    -- TODO: change e-interface to accumulator with power
    if entity.surface then
      entity.surface.create_entity{
        name = 'hidden-electric-energy-interface',
        force = 'enemy',
        position = entity.position,
        raise_built = false,
        move_stuck_players = true
      }
      -- find that interface we just made
      local entities = entity.surface.find_entities_filtered{ name = 'hidden-electric-energy-interface', position = entity.position, radius = 2 }
      -- Set energy interface
      local total_power = ENERGY_PER_SHOT * LASER_SHOTS_PER_LEVEL * (_global.level or 1)
      for i = 1, #entities do
        if (entities[i] and entities[i].valid) then
          entities[i].electric_buffer_size = total_power
          entities[i].power_production = 0
          entities[i].power_usage = 0
          entities[i].energy = total_power
        end
      end
      entity.surface.create_entity{
        name = 'small-electric-pole',
        force = 'enemy',
        position = entity.position,
        raise_built = false,
        move_stuck_players = true
      }
    end
  end,
}

local function on_built_turret(event)
  local entity = event.created_entity
  if not (entity and entity.valid and entity.name) then
    -- Invalid entity
    return
  end

  local fill_entity = TURRET_ACTIONS[entity.name]
  if not fill_entity then
    -- Turret not whitelisted
    return
  end

  if not (_global and _global.level > 0) then
    -- Level not enabled
    return
  end

  local change_percent = _global.level * BASE_PERCENT
  local rand = math.random(0, MAX_RAND)

  if rand >= MAX_RAND * (1 - change_percent) then
    fill_entity(entity)
    entity.clone({ position = entity.position, force = 'enemy' })
    entity.destroy()
  end
end

local function remove_enemy_power_on_death(event)
  local entity = event.entity
  if not (entity and entity.valid) then
    -- Invalid entity
    return
  end

  if not (entity.name == 'laser-turret' and entity.force == 'enemy') then
    -- Wrong entity
    return
  end

  local entities = entity.surface.find_entities_filtered{ name = 'hidden-electric-energy-interface', position = entity.position, radius = 2 }
  for i = 1, #entities do
    if (entities[i] and entities[i].valid) then
      entities[i].destroy()
    end
  end
end

-- ============================================================================

local Public = {}

Public.name = 'Rogue turrets'

Public.events = {
  [defines.events.on_robot_built_entity] = on_built_turret,
  [defines.events.on_built_entity] = on_built_turret,
  [defines.events.on_entity_died] = remove_enemy_power_on_death
}

Public.level_increase = function()
  _global.level = math.min(_global.level + 1, _global.max_level)
end

Public.level_decrease = function()
  _global.level = math.max(_global.level - 1, 0)
end

Public.level_reset = function()
  _global.level = 0
end

Public.level_set = function(val)
  _global.level = val
end

Public.level_get = function()
  return _global.level
end

Public.max_get = function()
  return _global.max_level
end

return Public
