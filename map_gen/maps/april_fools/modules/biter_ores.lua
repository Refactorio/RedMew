-- Spawns ores on biter death
-- WIP

local Global = require 'utils.global'
local math = require 'utils.math'

local RANDOM_ORES = false
local BASE_ORE_AMOUNT = 5 -- ore spawned per small biter, per level
local BASIC_ORES = {'coal','stone','iron-ore','copper-ore'}
local URANIUM_CHANCE = 5 -- chance for uranium ore. All others will share the remaining chance
local ORE_SEARCH_RADIUS = RANDOM_ORES and 1 or 20 -- how far away do we look for ores before spawning a new one

local _global = {
  level = 0, --1 to enabled by defualt
  max_level = 10,
}

Global.register(_global, function(tbl) _global = tbl end)

local ENEMY_ORE_MULTIPLIER = { -- roughly in order of evolution percentage required to see these biters
  ['small-biter']           = 1,
  ['small-spitter']         = 2,
  ['small-worm-turret']     = 5,
  ['medium-biter']          = 2,
  ['medium-spitter']        = 4,
  ['medium-worm-turret']    = 10,
  ['big-biter']             = 5,
  ['big-spitter']           = 10,
  ['big-worm-turret']       = 25,
  ['behemoth-biter']        = 10,
  ['behemoth-spitter']      = 20,
  ['behemoth-worm-turret']  = 50,
  ['biter-spawner']         = 10,
  ['spitter-spawner']       = 20
}

-- ============================================================================
local function spawn_ores_on_death(event)
  if not (_global and _global.level > 0) then
    -- Level not enabled
    return
  end

  -- check if entity is biter, worm, or spawner
  local entity = event.entity
  if entity.type ~= 'unit' and entity.type ~= 'turret' and entity.type ~= 'unit-spawner' then
    return
  end
  local ore_amount_to_add = _global.level * ENEMY_ORE_MULTIPLIER[entity.name] * BASE_ORE_AMOUNT
  local position = entity.position
  local surface = entity.surface
  local ore_type

  --first, look for ores on the tile the biter died, and add ores to that ore if possible
  local found_ores = surface.find_entities_filtered{position = position, radius = .1, type = 'resource'}
  if #found_ores == 0 then
    --no ore found on biter tile
    found_ores = surface.find_entities_filtered{position = position, radius = ORE_SEARCH_RADIUS, type = 'resource'}
    if #found_ores == 0 then
      --no ore found nearby, decide on a new ore to spawn
      if math.random(1,100) < URANIUM_CHANCE then
        ore_type = 'uranium-ore'
      else
        ore_type = BASIC_ORES[math.random(1,#BASIC_ORES)]
      end
    else
      -- found nearby ore, use that one
      ore_type = found_ores[math.random(1,#found_ores)].name
    end

    if surface.get_tile(position).collides_with("ground-tile") then
      surface.create_entity{name = ore_type, position = position, amount = ore_amount_to_add}
    end
    --return since we might have changed found_ores
    return
  else
    -- ore on biters tile, add to that ore instead
    found_ores[1].amount = found_ores[1].amount + ore_amount_to_add
  end
end

-- ============================================================================
local Public = {}

Public.name = 'Biter Ores'

Public.events = {
  [defines.events.on_entity_died] = spawn_ores_on_death
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
