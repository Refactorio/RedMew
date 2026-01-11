-- hides recipe groups from random players. If a player is targeted again, it will revert back to normal
-- only works with vanilla item-groups.
-- in future possible change to on_init to populate item_groups with all detected item groups?
-- WIP

local Event = require 'utils.event'
local Global = require 'utils.global'

local BASE_TARGETS = 1 -- how many targets per level
local CHANGE_TARGET_INTERVAL = _DEBUG and 60 * 10 or 60 * 180 -- 180sec

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

  if #game.connected_players > 0 then
    for j=1, num_targets do
      local player_index = math.random(1, #game.connected_players)
      local duplicate = false
      --check that randomly selected player is not in old list
      for k=1, #_global.rand_targets do
        if game.connected_players[player_index].name == _global.rand_targets[k].name then
          duplicate = true -- target was previously targeted, so enable them and take them off the list
          _global.rand_targets[k].enable_recipe_groups()
          _global.rand_targets[k].enable_recipe_subgroups()
          _global.rand_targets[k] = nil
        end
      end

      if duplicate == false then -- this is a new target
        _global.rand_targets[j] = game.connected_players[player_index]
        _global.rand_targets[j].disable_recipe_groups()
        _global.rand_targets[j].disable_recipe_subgroups()
      end
    end
  end
end

-- ============================================================================

local Public = {}

Public.name = 'Unorganized Recipes'

Public.on_nth_tick = {
  [CHANGE_TARGET_INTERVAL] = change_targets,
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
