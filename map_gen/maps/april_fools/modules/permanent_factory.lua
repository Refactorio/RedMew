-- Any placed entity has a chance to become permanent
-- WIP

local Global = require 'utils.global'

local BASE_PERCENT = 0.01
local MAX_RAND = 100

local _global = {
  level = 0,
  max_level = 10,
}

Global.register(_global, function(tbl) _global = tbl end)

-- ============================================================================

local function on_built_entity(event)
  local entity = event.entity
  if not (entity and entity.valid) then
    -- Invalid entity
    return
  end

  if not (_global and _global.level > 0) then
    -- Level not enabled
    return
  end

  local permanent_percent = _global.level * BASE_PERCENT
  local rand = math.random(0, MAX_RAND)

  if rand <= MAX_RAND*(1 - permanent_percent) then
    -- Normal construction
    return
  else
    entity.destructible = true
    entity.minable_flag = false
  end
end

-- ============================================================================

local Public = {}

Public.name = 'Permanent Structures'

Public.events = {
  [defines.events.on_robot_built_entity] = on_built_entity,
  [defines.events.on_built_entity] = on_built_entity,
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
