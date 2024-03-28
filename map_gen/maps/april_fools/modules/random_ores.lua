-- Each ore tile has 1% chance to mutate into another ore (every patch becomes a mixed ore patch)
-- Complete

local Global = require 'utils.global'
local table = require 'utils.table'

local BASE_PERCENT = 0.01
local MAX_RAND = 100

local _global = {
  level = 0, --1 to enabled by defualt
  max_level = 10,
}

Global.register(_global, function(tbl) _global = tbl end)

local ORES = {
  {'iron-ore', 10},
  {'copper-ore', 7},
  {'stone', 5},
  {'coal', 3},
  {'uranium-ore', 1},
}

local ALLOWED_DRILLS = {
  ['burner-mining-drill'] = true,
  ['electric-mining-drill'] = true,
}

-- ============================================================================

local function on_built_miner(event)
  local entity = event.created_entity
  if not (entity and entity.valid and entity.name and ALLOWED_DRILLS[entity.name]) then
    -- Invalid entity
    return
  end

  if not (_global and _global.level > 0) then
    -- Level not enabled
    return
  end

  local surface = entity.surface
  local position = entity.position
  local radius = entity.prototype.mining_drill_radius

  if not (surface and surface.valid) then
    -- Invalid surface
    return
  end

  local ore_tiles = surface.find_entities_filtered{
    position = position,
    radius = radius or 1.5,
    type = 'resource',
  }

  for _, ore in pairs(ore_tiles) do
    if (ore and ore.valid) then
      local extra_percent = _global.level * BASE_PERCENT
      local rand = math.random(0, MAX_RAND)

      if rand >= MAX_RAND*(1 - extra_percent) then
        local rand_ore = table.get_random_weighted(ORES)

        if (rand_ore ~= ore.name) and surface.get_tile(ore.position.x, ore.position.y).collides_with('ground-tile') then
          local amount = ore.amount
          local ore_position = ore.position
          ore.destroy()
          surface.create_entity{
            name = rand_ore,
            amount = amount,
            position = ore_position,
          }
        end

      end
    end
  end
end

-- ============================================================================

local Public = {}

Public.name = 'Magic drills'

Public.events = {
  [defines.events.on_robot_built_entity] = on_built_miner,
  [defines.events.on_built_entity] = on_built_miner,
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
