-- Spawns biters of a level scaling with _global.level on every player that has alt_mode toggled ON
-- Complete

local Event = require 'utils.event'
local Global = require 'utils.global'
local math = require 'utils.math'

local SPAWN_INTERVAL = 60 * 60 * 3 -- 3min
local UNIT_COUNT = 1 -- Number of units spawned per enemy listed in each ENEMY_GROUP

local _global = {
  level = 0, --1 to enabled by defualt
  max_level = 10,
  alt_biters_players = {},
}

Global.register(_global, function(tbl) _global = tbl end)

local ENEMY_GROUPS = {
  { 'small-biter', 'small-spitter' },
  { 'small-biter', 'small-spitter', 'small-worm-turret' },
  { 'medium-biter', 'medium-spitter' },
  { 'medium-biter', 'medium-spitter', 'medium-worm-turret' },
  { 'big-biter', 'big-spitter' },
  { 'big-biter', 'big-spitter', 'big-worm-turret' },
  { 'behemoth-biter', 'behemoth-spitter' },
  { 'behemoth-biter', 'behemoth-spitter', 'behemoth-worm-turret' },
  { 'behemoth-biter', 'behemoth-spitter', 'behemoth-worm-turret', 'biter-spawner' },
  { 'behemoth-biter', 'behemoth-spitter', 'behemoth-worm-turret', 'biter-spawner', 'spitter-spawner' },
}

Event.add(defines.events.on_player_removed, function(event)
  _global.alt_biters_players[event.player_index] = nil
end)

-- ============================================================================

local function spawn_biters_nearby_players()
  if not (_global and _global.level > 0) then
    -- Level not enabled
    return
  end

  local index_from_level = math.clamp(_global.level, 1, #ENEMY_GROUPS)
  local biters = ENEMY_GROUPS[index_from_level]

  for _, player in pairs(game.players) do
    if (player and player.valid and _global.alt_biters_players[player.name]) then
      local position = player.physical_position

      for i=1, UNIT_COUNT do
        local unit_index = math.random(1, #biters)
        player.physical_surface.create_entity{
          name = biters[unit_index],
          position = position,
          force = 'enemy',
          target = player.character,
          move_stuck_players = true,
        }
      end
    end
  end
end

-- toggle alt-biters for the player when alt-mode is toggled
local function on_player_toggled_alt_mode(event)
  local player_index = event.player_index
  if player_index == nil then
    return
  end

  local player = game.get_player(player_index)
  if (player and player.valid and player.name) then
    _global.alt_biters_players[player.name] = event.alt_mode or false
  end
end

-- turn off alt-mode on game join, and set alt-biters to off
local function on_player_joined_game(event)
  local player_index = event.player_index
  if player_index == nil then
    return
  end

  local player = game.get_player(player_index)
  if (player and player.valid and player.name) then
    player.game_view_settings.show_entity_info = false
    _global.alt_biters_players[player.name] = false
  end
end

-- ============================================================================

local Public = {}

Public.name = 'Alternative biters'

Public.events = {
  [defines.events.on_player_toggled_alt_mode] = on_player_toggled_alt_mode,
  [defines.events.on_player_joined_game] = on_player_joined_game,
}

Public.on_nth_tick = {
  [SPAWN_INTERVAL] = spawn_biters_nearby_players,
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
