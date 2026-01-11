-- rotten egg, produces pollution. Similar to golden goose
-- SPAWN_INTERVAL and CHANGE_EGGS_INTERVAL should be set to the number of ticks between the event triggering

local Event = require 'utils.event'
local Global = require 'utils.global'

local BASE_EGGS = 1 -- how many eggs per level
local SPAWN_INTERVAL = 60 * 5 -- 5sec
local CHANGE_EGGS_INTERVAL = 60 * 101 -- 100sec
local DROP_AMOUNT = 1 -- 60/m ~ 6x mining drills

local _global = {
  level = 0, -- 1 to enabled by defualt
  max_level = 10,
  rand_eggs = {},
}

Global.register(_global, function(tbl) _global = tbl end)

Event.add(defines.events.on_pre_player_removed, function(event)
  local player = game.get_player(event.player_index)
  if not player then
    return
  end
  for i, target_player in pairs(_global.rand_eggs) do
    if target_player == player then
      _global.rand_eggs[i] = nil
    end
  end
end)

-- ============================================================================

local function clear_eggs()
  for j=1, #_global.rand_eggs do
    _global.rand_eggs[j] = nil
  end
end

local function change_eggs()
  if not (_global and _global.level > 0) then
    -- Level not enabled
    return
  end

  local num_eggs = _global.level * BASE_EGGS

  for j=1, num_eggs do
    _global.rand_eggs[j] = nil
  end

  if #game.connected_players > 0 then
    for j=1, num_eggs do
      local player_index = math.random(1, #game.connected_players)
      _global.rand_eggs[j] = game.connected_players[player_index]
    end
  end
end

local function eggs_spawn_pollution()
  if not (_global and _global.rand_eggs and (#_global.rand_eggs > 0)) then
    -- No eggs
    return
  end

  for _, player in pairs(_global.rand_eggs) do
    if (player and player.valid) then
      local surface = player.physical_surface
      local position = player.physical_position
      local amount = (_global.level or 1) * DROP_AMOUNT
      -- must be extra cautious with surface & players as they may be teleported across temporary surfaces
      if (surface and surface.valid and position) then
        surface.pollute(position, amount)
      end
    end
  end
end

-- ============================================================================

local Public = {}

Public.name = 'Rotten egg'

Public.on_nth_tick = {
  [CHANGE_EGGS_INTERVAL] = change_eggs,
  [SPAWN_INTERVAL] = eggs_spawn_pollution,
}

Public.level_increase = function()
  _global.level = math.min(_global.level + 1, _global.max_level)
end

Public.level_decrease = function()
  _global.rand_eggs[_global.level] = nil
  _global.level = math.max(_global.level - 1, 0)
end

Public.level_reset = function()
  clear_eggs()
  _global.level = 0
end

Public.level_set = function(val)
  clear_eggs()
  _global.level = val
end

Public.level_get = function()
  return _global.level
end

Public.max_get = function()
  return _global.max_level
end

return Public
