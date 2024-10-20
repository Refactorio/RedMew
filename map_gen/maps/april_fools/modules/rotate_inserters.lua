-- Inserters are sometimes randomly rotated when placed by player or bots
-- Complete

local Global = require 'utils.global'

local BASE_PERCENT = 0.05
local MAX_RAND = 100 * 3

local _global = {
  level = 0,
  max_level = 10,
}

Global.register(_global, function(tbl) _global = tbl end)

-- ============================================================================

local function on_built_inserter(event)
  local entity = event.entity
  if not (entity and entity.valid) then
    -- Invalid entity
    return
  end

  if not (entity.prototype and entity.prototype.type == 'inserter') then
    -- Wrong entity type
    return
  end

  if not (_global and _global.level > 0) then
    -- Level not enabled
    return
  end

  local rotate_percent = _global.level * BASE_PERCENT
  local rand = math.random(0, MAX_RAND)

  if rand <= MAX_RAND*(1 - rotate_percent) then
    -- No Rotation
    return
  elseif rand <= MAX_RAND*(1 - rotate_percent * 2/3) then
    -- Single Rotation
    entity.rotate()
    return
  elseif rand <= MAX_RAND*(1 - rotate_percent * 1/3) then
    -- Double Rotation
    entity.rotate()
    entity.rotate()
    return
  elseif rand <= MAX_RAND then
    -- Reverse Rotation
    entity.rotate({reverse = true})
    return
  end
end

-- ============================================================================

local Public = {}

Public.name = 'Dancing inserters'

Public.events = {
  [defines.events.on_robot_built_entity] = on_built_inserter,
  [defines.events.on_built_entity] = on_built_inserter,
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
