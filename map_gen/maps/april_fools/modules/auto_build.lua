-- auto-builds the item in a random players cursor if possible
-- WIP

local Event = require 'utils.event'
local Global = require 'utils.global'

local BASE_TARGETS = 1 -- how many targets per level
local BUILD_INTERVAL = 60 * 25 -- 25sec
local CHANGE_TARGET_INTERVAL = _DEBUG and 60 * 1 or 60 * 100 -- 100sec

local _global = {
  level = 0, -- 1 to enabled by defualt
  max_level = 10,
  rand_targets = {},
}

Global.register(_global, function(tbl) _global = tbl end)

Event.add(defines.events.on_pre_player_removed, function(event)
  local player = game.get_player(event.player_index)
  if not player then
    return
  end
  for i, target_player in pairs(_global.rand_targets) do
    if target_player == player then
      _global.rand_targets[i] = nil
    end
  end
end)

-- ============================================================================

local function clear_targets()
  for j=1, #_global.rand_targets do
    _global.rand_targets[j] = nil
  end
end

local function change_targets()
  if not (_global and _global.level > 0) then
    -- Level not enabled
    return
  end

  local num_targets = math.min(#game.connected_players, _global.level * BASE_TARGETS)

  for j=1, num_targets do
    _global.rand_targets[j] = nil
  end

  if #game.connected_players > 0 then
    for j=1, num_targets do
      local player_index = math.random(1, #game.connected_players)
      _global.rand_targets[j] = game.connected_players[player_index]
    end
  end
end

local function try_auto_build()
  if not (_global and _global.rand_targets and (#_global.rand_targets > 0)) then
    -- No targets
    return
  end
-- useful functions:
-- surface.find_non_colliding_position, surface.find_non_colliding_position_in_box
-- player.can_build_from_cursor, player.build_from_cursor
--
  local cursor_item
  local surface
  local build_position
  for _, player in pairs(_global.rand_targets) do
    if not (player and player.valid) then
      goto skip
    end

    surface = player.surface
    if player.cursor_stack.valid_for_read then
      cursor_item = player.cursor_stack.name
    else
      goto skip --cursor not valud to read, i.e. just before spawning
    end
    if cursor_item == nil then
      goto skip -- no item in cursor
    end

    -- randomly pick a position near the player, check for a valid nearby location
    build_position = {player.position.x + math.random(-5,5),player.position.y + math.random(-5,5)}
    build_position = surface.find_non_colliding_position(cursor_item,build_position, 5, .1)
    if build_position == nil then
      goto skip -- no valud build position
    end

    -- must be extra cautious with surface & players as they may be teleported across temporary surfaces
    if (surface and surface.valid and build_position) then
      if player.can_build_from_cursor{position = build_position} then
        player.build_from_cursor{position = build_position}
      end
    end
  end

  ::skip::
end

-- ============================================================================

local Public = {}

Public.name = 'Auto Build'

Public.on_nth_tick = {
  [CHANGE_TARGET_INTERVAL] = change_targets,
  [BUILD_INTERVAL] = try_auto_build,
}

Public.level_increase = function()
  _global.level = math.min(_global.level + 1, _global.max_level)
end

Public.level_decrease = function()
  _global.rand_targets[_global.level] = nil
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
