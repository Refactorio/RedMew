-- Increases research costs and enables marathon mode
-- Complete

local Global = require 'utils.global'

local COST_STEP = 1.0

local _global = {
  level = 0,
  max_level = 9,
}

Global.register(_global, function(tbl) _global = tbl end)

-- ============================================================================

local function update_price_multiplier()
  local level = math.max(0, _global.level)

  game.difficulty_settings.technology_price_multiplier = (level + 1) * COST_STEP
end

-- ============================================================================

local Public = {}

Public.name = 'Marathon'

Public.level_increase = function()
  _global.level = math.min(_global.level + 1, _global.max_level)
  update_price_multiplier()
end

Public.level_decrease = function()
  _global.level = math.max(_global.level - 1, 0)
  update_price_multiplier()
end

Public.level_reset = function()
  _global.level = 0
  update_price_multiplier()
end

Public.level_set = function(val)
  _global.level = val
  update_price_multiplier()
end

Public.level_get = function()
  return _global.level
end

Public.max_get = function()
  return _global.max_level
end

return Public
