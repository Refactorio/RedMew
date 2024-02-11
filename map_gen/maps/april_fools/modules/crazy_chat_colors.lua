-- Changes player color with every message
-- Complete

local Global = require 'utils.global'
local Colors = require 'resources.color_presets'

local COLORS = {}
for _, color in pairs(Colors) do
  table.insert(COLORS, color)
end

local BASE_PERCENT = 0.1
local MAX_RAND = 100

local _global = {
  level = 0,
  max_level = 10,
}

Global.register(_global, function(tbl) _global = tbl end)

-- ============================================================================

local function on_console_chat(event)
  local index = event.player_index
  if index == nil then
    return
  end

  local change_percent = _global.level * BASE_PERCENT
  local rand = math.random(0, MAX_RAND)

  if rand >= MAX_RAND*(1 - change_percent) then
    local color = COLORS[math.random(1, #COLORS)]
    local player = game.get_player(index)
    player.color = color
    player.chat_color = color
  end
end

-- ============================================================================

local Public = {}

Public.name = 'Disco players'

Public.events = {
  [defines.events.on_console_chat] = on_console_chat,
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
