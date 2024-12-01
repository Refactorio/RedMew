-- This module spawns ore in place of mined entities
-- By default, only entities not-allowed on resources spawn ore when mined away/upgraded
--
-- Params:
-- multiplier? double, defines the ore_dropped/entity_health ratio
-- resources? table<string>, array of resources to spawn
-- handler? function, handler for the event. Gets passed a valid LuaEntity, must return True (take action) / False (pass)

local Event = require 'utils.event'
local AllowedEntities = require 'map_gen.maps.danger_ores.modules.allowed_entities'
local max = math.max
local floor = math.floor
local random = math.random

local default_resources = {
  'iron-ore', 'iron-ore', 'iron-ore', 'iron-ore', 'iron-ore', 'iron-ore',
  'copper-ore', 'copper-ore', 'copper-ore', 'copper-ore',
  'coal', 'coal', 'coal', 'coal',
  'stone',
}
local function default_handler(entity)
  if entity.type == 'simple-entity' or entity.type == 'tree' then
    return false
  end
  if entity.name == 'entity-ghost' or entity.name == 'tile-ghost' then
    return false
  end
  return not AllowedEntities.is_allowed(entity)
end

---@param config
---@field multiplier? double `defines the ore dropped/entity_health ratio`
---@field resources? table<string> `array of resources to spawn`
---@field handler? function `handler for the event. Gets passed a valid LuaEntity, must return True (take action) / False (pass)`
return function(config)
  config = config or {}
  local multiplier = config.multiplier or 1
  local resource_pool = config.resources or default_resources
  local handler = config.handler or default_handler

  local function on_mined(event)
    local entity = event.entity
    if not (entity and entity.valid) then
      return
    end

    if not handler(entity) then
      return
    end

    local area = entity.bounding_box
    local left_top, right_bottom = area.left_top, area.right_bottom
    local x1, y1 = floor(left_top.x), floor(left_top.y)
    local x2, y2 = floor(right_bottom.x), floor(right_bottom.y)
    local size_x = x2 - x1 + 1
    local size_y = y2 - y1 + 1
    local base = size_x * size_y

    local health = entity.prototype.get_max_health(entity.quality)
    local amount = max(1, floor(multiplier * health / base))
    local can_place_entity = entity.surface.can_place_entity
    local create_entity = entity.surface.create_entity

    local def = { name = resource_pool[random(#resource_pool)], amount = amount }
    for x = x1, x2 do
      for y = y1, y2 do
        def.position = { x, y }
        if can_place_entity(def) then create_entity(def) end
      end
    end
  end

  Event.add(defines.events.on_player_mined_entity, on_mined)
  Event.add(defines.events.on_robot_mined_entity, on_mined)
  Event.add(defines.events.on_entity_died, function(event)
    local force = event.entity and event.entity.force
    if force.name ~= 'player' then
      return
    end
    on_mined(event)
  end)
end
