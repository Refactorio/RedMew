-- Spawns random non-damaging explosions on random players as a jump-scare
-- WIP
local Event = require 'utils.event'
local Global = require 'utils.global'

local BASE_TARGETS = 1 -- how many targets per level
local EXPLOSION_INTERVAL = _DEBUG and 60 * 5 or 60 * 60 -- 60sec
local CHANGE_TARGET_INTERVAL = _DEBUG and 60 * 10 or 60 * 180 -- 180 seconds


local _global = {
  level = 0, -- 1 to enabled by defualt
  max_level = 10,
  rand_target = {},
}

Global.register(_global, function(tbl) _global = tbl end)

local EXPLOSION_GROUPS = {
  { 'water-splash' },
  { 'water-splash', 'explosion' },
  { 'water-splash', 'explosion', 'land-mine-explosion' },
  { 'explosion', 'land-mine-explosion', 'grenade-explosion' },
  { 'land-mine-explosion', 'grenade-explosion', 'medium-explosion' },
  { 'grenade-explosion', 'medium-explosion' },
  { 'medium-explosion', 'big-explosion' },
  { 'big-explosion', 'massive-explosion', 'big-artillery-explosion' },
  { 'massive-explosion', 'big-artillery-explosion' },
  { 'massive-explosion', 'big-artillery-explosion', 'nuke-explosion' },
}

Event.add(defines.events.on_pre_player_removed, function(event)
  local player = game.get_player(event.player_index)
  if not player then
    return
  end
  for i, target_player in pairs(_global.rand_target) do
    if target_player == player then
      _global.rand_target[i] = nil
    end
  end
end)

-- ============================================================================

local function clear_targets()
  for j=1, #_global.rand_target do
    _global.rand_target[j] = nil
  end
end

local function change_targets()
  if not (_global and (_global.level > 0)) then
    -- Level not enabled
    return
  end
  -- without taking the min of connected players, and the desired targets, it's possible for 1 player to get ALL the explosions
  -- The code would then randomly choose an explosion for each target, so you might get a water splash and a normal explosion at the same time.
  local num_targets = math.min(_global.level * BASE_TARGETS, #game.connected_players)

  for j=1, num_targets do
    _global.rand_target[j] = nil
  end

  if #game.connected_players > 0 then
    for j=1, num_targets do
      local player_index = math.random(1, #game.connected_players)
      _global.rand_target[j] = game.connected_players[player_index]
    end
  end
end

local function explode_targets()
  if not (_global and _global.rand_target and (#_global.rand_target > 0)) then
    -- No targets
    return
  end
  local index_from_level = math.clamp(_global.level, 1, #EXPLOSION_GROUPS) --luacheck: ignore 143 math.clamp does in fact exist
  local explosions = EXPLOSION_GROUPS[index_from_level]

  for _, player in pairs(_global.rand_target) do
    if (player and player.valid) then
      local surface = player.surface
      local position = player.position
      local explosion_index = math.random(1, #explosions)
      -- must be extra cautious with surface & players as they may be teleported across temporary surfaces
      if (surface and surface.valid and position) then
        surface.create_entity{
          name = explosions[explosion_index],
          position = position,
        }
      end
    end
  end
end

-- ============================================================================

local Public = {}
Public.name = 'Explosion Scare'

Public.on_nth_tick = {
  [CHANGE_TARGET_INTERVAL] = change_targets,
  [EXPLOSION_INTERVAL] = explode_targets,
}

Public.level_increase = function()
  _global.level = math.min(_global.level + 1, _global.max_level)
end

Public.level_decrease = function()
  _global.rand_target[_global.level] = nil
  _global.level = math.max(_global.level - 1, 0)
end

Public.level_reset = function()
  clear_targets()
  _global.level = 0
end

Public.level_set = function(val)
  clear_targets()
  _global.level = val
end

Public.level_get = function()
  return _global.level
end

Public.max_get = function()
  return _global.max_level
end

return Public
