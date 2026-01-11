-- golden goose
-- SPAWN_INTERVAL and CHANGE_GEESE_INTERVAL should be set to the number of ticks between the event triggering

local Event = require 'utils.event'
local Global = require 'utils.global'

local BASE_GEESE = 1 -- how many geese per level
local SPAWN_INTERVAL = 60 * 5 -- 5sec
local CHANGE_GEESE_INTERVAL = 60 * 100 -- 100sec
local DROP_AMOUNT = 1

local _global = {
  level = 0, -- 1 to enabled by defualt
  max_level = 10,
  rand_geese = {},
}

Global.register(_global, function(tbl) _global = tbl end)

Event.add(defines.events.on_pre_player_removed, function(event)
  local player = game.get_player(event.player_index)
  if not player then
    return
  end
  for i, target_player in pairs(_global.rand_geese) do
    if target_player == player then
      _global.rand_geese[i] = nil
    end
  end
end)

-- ============================================================================

local function clear_geese()
  for j=1, #_global.rand_geese do
    _global.rand_geese[j] = nil
  end
end

local function change_geese()
  if not (_global and (_global.level > 0)) then
    -- Level not enabled
    return
  end

  local num_geese = _global.level * BASE_GEESE

  for j=1, num_geese do
    _global.rand_geese[j] = nil
  end

  if #game.connected_players > 0 then
    for j=1, num_geese do
      local player_index = math.random(1, #game.connected_players)
      _global.rand_geese[j] = game.connected_players[player_index]
    end
  end
end

local function geese_spawn_coin()
  if not (_global and _global.rand_geese and (#_global.rand_geese > 0)) then
    -- No geese
    return
  end

  for _, player in pairs(_global.rand_geese) do
    if (player and player.valid) then
      local surface = player.physical_surface
      local position = player.physical_position
      -- must be extra cautious with surface & players as they may be teleported across temporary surfaces
      if (surface and surface.valid and position) then
        surface.create_entity{
          name = 'item-on-ground',
          position = position,
          stack = {name = 'coin', count = DROP_AMOUNT},
        }
      end
    end
  end
end

-- ============================================================================

local Public = {}
Public.name = 'Golden goose'

Public.on_nth_tick = {
  [CHANGE_GEESE_INTERVAL] = change_geese,
  [SPAWN_INTERVAL] = geese_spawn_coin,
}

Public.level_increase = function()
  _global.level = math.min(_global.level + 1, _global.max_level)
end

Public.level_decrease = function()
  _global.rand_geese[_global.level] = nil
  _global.level = math.max(_global.level - 1, 0)
end

Public.level_reset = function()
  clear_geese()
  _global.level = 0
end

Public.level_set = function(val)
  clear_geese()
  _global.level = val
end

Public.level_get = function()
  return _global.level
end

Public.max_get = function()
  return _global.max_level
end

return Public
