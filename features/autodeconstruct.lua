--Author: Valansch

local Event = require 'utils.event'
local Token = require 'utils.token'
local Task = require 'utils.task'

local function is_depleted(drill, entity)
    local position = drill.position
    local area
    local radius

    -- use prototype to get drill radius
    if drill.prototype.mining_drill_radius then
        radius = drill.prototype.mining_drill_radius
        area = {{position.x - radius, position.y - radius}, {position.x + radius, position.y + radius}}
    end

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
    if entity.minable.fluid_amount then
        return nil
    end

    local position = entity.position
    local area = {{position.x - 1, position.y - 1}, {position.x + 1, position.y + 1}}
    local drills = event.entity.surface.find_entities_filtered {area = area, type = 'mining-drill'}
    for _, drill in ipairs(drills) do
        if drill.name ~= 'pumpjack' and is_depleted(drill, entity) then
            Task.set_timeout_in_ticks(5, callback, drill)
        end
    end
end

Event.add(defines.events.on_resource_depleted, on_resource_depleted)
