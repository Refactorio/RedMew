--Author: Valansch

local Event = require 'utils.event'
local Token = require 'utils.token'
local Task = require 'utils.task'

global.mining_drill_radius_max = 1 -- Defines how far from the resource that depleted we look for a drill

local function is_depleted(drill, entity)
    local position = drill.position
    local mining_drill_radius = drill.prototype.mining_drill_radius

    if mining_drill_radius == nil then
      return false
    end

    local area = {{position.x - mining_drill_radius, position.y - mining_drill_radius}, {position.x + mining_drill_radius, position.y + mining_drill_radius}}

    for _, resource in pairs(drill.surface.find_entities_filtered {type = 'resource', area = area}) do
        if resource ~= entity and resource.name ~= 'crude-oil' then
            return false
        end
    end
    return true
end

local callback =
    Token.register(
    function(drill)
        if drill.valid then
            drill.order_deconstruction(drill.force)
        end
    end
)

local function on_resource_depleted(event)
    local entity = event.entity
    if entity.name == 'uranium-ore' then
        return nil
    end

    local position = entity.position
    local area = {{position.x - global.mining_drill_radius_max, position.y - global.mining_drill_radius_max}, {position.x + global.mining_drill_radius_max, position.y + global.mining_drill_radius_max}}
    local drills = event.entity.surface.find_entities_filtered {area = area, type = 'mining-drill'}
    for _, drill in ipairs(drills) do
        if drill.name ~= 'pumpjack' and is_depleted(drill, entity) then
            Task.set_timeout_in_ticks(5, callback, drill)
        end
    end
end

local function on_built_entity(event)
  if event.created_entity.type ~= 'mining-drill' then return end
  if event.created_entity.prototype.mining_drill_radius > global.mining_drill_radius_max then
      global.mining_drill_radius_max = event.created_entity.prototype.mining_drill_radius
  end
end

Event.add(defines.events.on_resource_depleted, on_resource_depleted)
Event.add(defines.events.on_robot_built_entity, on_built_entity)
Event.add(defines.events.on_built_entity, on_built_entity)
