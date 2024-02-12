-- Spawns "meteors" that spawn a boulder, and dense random ores, and biters, and maybe nests
-- WIP

local Global = require 'utils.global'
local math = require 'utils.math'

local SPAWN_INTERVAL = _DEBUG and 60 * 1 or 60 * 180 -- 180sec
local UNIT_COUNT = 10 -- Balance Number of units spawned per enemy listed in each ENEMY_GROUP
local METEOR_COUNT = 1 -- meteors per spawn interval
local METEOR_SIZE = 7 -- radius, Balance
local METEOR_DAMAGE = 50 -- Balance
local ORE_DENSITY = 10 -- Balance, Must be at least 8?
local ORE_COMPLEXITY = 5 -- Percent chance for each of the 5 ore types to spawn, otherwise mixed ores without uranium will spawn.

local _global = {
  level = 0, --1 to enabled by defualt
  max_level = 10,
}

Global.register(_global, function(tbl) _global = tbl end)

local ENEMY_GROUPS = {
  { 'small-biter'},
  { 'small-biter', 'small-spitter', 'small-worm-turret', 'biter-spawner'},
  { 'small-biter', 'small-spitter','medium-biter','small-worm-turret', 'biter-spawner', 'spitter-spawner'  },
  { 'small-biter', 'small-spitter','medium-biter', 'medium-spitter','small-worm-turret', 'biter-spawner', 'spitter-spawner'  },
  { 'medium-biter', 'medium-spitter', 'big-biter', 'big-spitter','small-worm-turret','medium-worm-turret', 'biter-spawner', 'spitter-spawner'  },
  { 'medium-biter', 'medium-spitter', 'big-biter', 'big-spitter', 'big-worm-turret','medium-worm-turret', 'biter-spawner', 'spitter-spawner'  },
  { 'big-biter', 'big-spitter','behemoth-biter', 'behemoth-spitter', 'medium-worm-turret','big-worm-turret', 'biter-spawner', 'spitter-spawner'  },
  { 'big-biter', 'big-spitter','behemoth-biter', 'behemoth-spitter', 'medium-worm-turret', 'big-worm-turret', 'biter-spawner', 'spitter-spawner'  },
  { 'big-biter', 'big-spitter','behemoth-biter', 'behemoth-spitter', 'big-worm-turret','behemoth-worm-turret', 'biter-spawner', 'spitter-spawner' },
  { 'behemoth-biter', 'behemoth-spitter', 'behemoth-worm-turret', 'biter-spawner', 'spitter-spawner' },
}
local BASIC_ORES = {'coal','stone','iron-ore','copper-ore'}
local ALL_ORES = {'coal','stone','iron-ore','copper-ore','uranium-ore'}

-- ============================================================================

local function drop_meteors()
  --[[ Large function, lots of steps. May want to split out into several functions later
      [X] Find a player to use their surface 
      [X] Generate a random position on the map
      [X] Spawn a rock
      [X] Damage Nearby Entities
      [X] Spawn Ores
      [X] Spawn Biters
  --]]
  if not (_global and _global.level > 0) then
    -- Level not enabled
    return
  end
  local player = nil
  local surface = nil
  for meteor_num=1, METEOR_COUNT do
    -- find a random player so we can use their surface
    if #game.connected_players > 0 then
      player = game.connected_players[math.random(1, #game.connected_players)]
      surface = player.surface
    else
      return -- no connected players
    end

    -- generate a random position in a random chunk
    local chunk_position = surface.get_random_chunk()
    local rand_x = math.random(0, 31)
    local rand_y = math.random(0, 31)
    local map_position = {x = chunk_position.x * 32 + rand_x, y = chunk_position.y * 32 + rand_y}

    -- Spawn Rock
    if surface.get_tile(map_position).collides_with('ground-tile') then
      surface.create_entity({name = 'rock-huge', position = map_position, move_stuck_players = true,})
      surface.create_entity({name = 'massive-explosion', position = map_position,})
    end

    -- Find nearby entities
    local damaged_entities = surface.find_entities_filtered{position = map_position, radius = METEOR_SIZE}
    -- Damage nearby entities
    if damaged_entities == nil then
      return
    else
      for _, entity in ipairs(damaged_entities) do
        if entity.is_entity_with_health then
          entity.damage(METEOR_DAMAGE,'enemy','impact')
        end
      end
    end
    
    -- Select ores to spawn
    local ore_selector = math.random(1,100)
    local ores = nil
    local ore_type = nil
    if ore_selector > 100 - 5 * ORE_COMPLEXITY then
      ores = 'individual'
      ore_type = ALL_ORES[math.random(1, #ALL_ORES)]
    else
      ores = 'mixed'
    end
    -- Spawn ores
    -- Loop over x, y, check in the circle, and spawn ores in a natural density
    -- aka code adapted from wube wiki console page for spawning a resource patch
    for y = -METEOR_SIZE, METEOR_SIZE do
      for x = -METEOR_SIZE, METEOR_SIZE do
        if (x * x + y * y < METEOR_SIZE * METEOR_SIZE) then
          a = (METEOR_SIZE + 1 - math.abs(x)) * 10
          b = (METEOR_SIZE + 1 - math.abs(y)) * 10
          if a < b then
            ore_amount = math.random(a * ORE_DENSITY - a * (ORE_DENSITY - 8), a * ORE_DENSITY + a * (ORE_DENSITY - 8))
          end
          if b < a then
            ore_amount = math.random(b * ORE_DENSITY - b * (ORE_DENSITY - 8), b * ORE_DENSITY + b * (ORE_DENSITY - 8))
          end
          if surface.get_tile(map_position.x + x, map_position.y + y).collides_with('ground-tile') then
            if ores == 'mixed' then
              ore_type = BASIC_ORES[math.random(1, #BASIC_ORES)]
            end
            surface.create_entity({name=ore_type, amount=ore_amount, position={map_position.x + x, map_position.y + y}})
          end
        end
      end
    end
    -- spawn biters
    local index_from_level = math.clamp(_global.level, 1, #ENEMY_GROUPS)
    local biters = ENEMY_GROUPS[index_from_level]
    for i=1, UNIT_COUNT do
      local unit_index = math.random(1, #biters)
      local biter_position = {
        map_position.x + math.random(-METEOR_SIZE, METEOR_SIZE),
        map_position.y + math.random(-METEOR_SIZE, METEOR_SIZE)}
      if surface.get_tile(biter_position).collides_with('ground-tile') then
        surface.create_entity{
          name = biters[unit_index],
          position = biter_position,
          force = 'enemy',
          -- target = player.character, -- try without player target? Will they behave normally?
        }
      end
    end
  end
end

-- ============================================================================

local Public = {}

Public.name = 'MeteOres'

Public.on_nth_tick = {
  [SPAWN_INTERVAL] = drop_meteors,
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
