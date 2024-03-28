-- crafting underground belt/pipes will no longer give an even number
-- Complete

local Global = require 'utils.global'

local BASE_PERCENT = 0.01
local MAX_RAND = 100

local _global = {
  level = 0,
  max_level = 10,
}

Global.register(_global, function(tbl) _global = tbl end)

local PAIR_NAMES = {
  ['underground-belt'] = true,
  ['fast-underground-belt'] = true,
  ['express-underground-belt'] = true,
  ['pipe-to-ground'] = true,
}

-- ============================================================================

local function on_player_crafted_item(event)
  local name = event.item_stack and event.item_stack.name
  if not (name and PAIR_NAMES[name]) then
    -- Invalid item
    return
  end

  local index = event.player_index
  if not index then
    return
  end

  local player = game.get_player(index)
  if not (player and player.valid) then
    -- Invalid player
    return
  end

  if not (_global and _global.level > 0) then
    -- Level not enabled
    return
  end

  local extra_percent = _global.level * BASE_PERCENT
  local rand = math.random(0, MAX_RAND)

  if rand >= MAX_RAND*(1 - extra_percent) then
    player.insert({ name = event.item_stack.name, count = 1 })
  end
end

-- ============================================================================

local Public = {}

Public.name = 'Orphan crafting'

Public.events = {
  [defines.events.on_player_crafted_item] = on_player_crafted_item,
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
