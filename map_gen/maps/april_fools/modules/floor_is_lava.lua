-- Floor is lava, a player that is AFK for ALLOWED_AFK_TIME ticks will be damaged every DAMAGE_INTERVAL ticks
-- Complete

local Global = require 'utils.global'

local DAMAGE_INTERVAL = 60 * 5 -- 5sec
local ALLOWED_AFK_TIME = 60 * 7 -- 7sec
local BASE_DAMAGE = 1

local _global = {
  level = 0, -- 1 to enabled by defualt
  max_level = 10,
}

Global.register(_global, function(tbl) _global = tbl end)

-- ============================================================================

local function damage_afk_players()
  if not (_global and _global.level > 0) then
    -- Level not enabled
    return
  end

  for _, player in pairs(game.players) do
    if (player and player.valid and player.character and player.character.valid) then
      if player.afk_time > ALLOWED_AFK_TIME then
        player.character.damage(BASE_DAMAGE * _global.level, 'enemy')
      end
    end
  end
end

-- ============================================================================

local Public = {}

Public.name = 'The floor is lava'

Public.on_nth_tick = {
  [DAMAGE_INTERVAL] = damage_afk_players,
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
