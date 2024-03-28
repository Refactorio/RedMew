-- Randmly changes shortcut items in player's quickbar
-- Complete

local Global = require 'utils.global'
local Item_list = require 'resources.item_list'

local BASE_PERCENT = 0.05
local MAX_RAND = 100
local CHANGE_INTERVAL = 60 * 12 --12sec
local SEARCHED_QUICKBAR_SLOTS = 100

local _global = {
  level = 0,
  max_level = 10,
}

Global.register(_global, function(tbl) _global = tbl end)

-- ============================================================================

local function change_quickbar_item()
  if not (_global and _global.level > 0) then
    -- Level not enabled
    return
  end

  local crazy_percent = _global.level * BASE_PERCENT

  for _, player in pairs(game.players) do
    if (player and player.valid) then
      local rand = math.random(0, MAX_RAND)
      if rand >= MAX_RAND*(1 - crazy_percent) then
        local valid_item, rand_item = false, false
        local max_attempts = 10
        while ((max_attempts > 0) and (not valid_item)) do
          rand_item = Item_list[math.random(1, #Item_list)]
          valid_item = (game.item_prototypes[rand_item] ~= nil)
          max_attempts = max_attempts - 1
        end
        if valid_item then
          local rand_position = math.random(1, SEARCHED_QUICKBAR_SLOTS)
          player.set_quick_bar_slot(rand_position, rand_item)
        end
      end
    end
  end
end

-- ============================================================================

local Public = {}

Public.name = 'Fuzzy quickbar'

Public.on_nth_tick = {
  [CHANGE_INTERVAL] = change_quickbar_item,
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
