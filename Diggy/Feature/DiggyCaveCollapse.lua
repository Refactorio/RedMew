--[[-- info
    Provides the ability to collapse caves when digging.
]]

-- dependencies
require 'utils.list_utils'

local Event = require 'utils.event'
local Template = require 'Diggy.Template'
local Mask = require 'Diggy.Mask'
local PressureMap = require 'Diggy.PressureMap'
local DiggyHole = require 'Diggy.Feature.DiggyHole'

-- this
local DiggyCaveCollapse = {}

--[[--
    @param surface LuaSurface
    @param position Position with x and y
    @param support_beam_range the supported range from this position
    @param support_removed boolean true if the location was removed
]]
local function update_pressure_map(surface, position, support_beam_range, support_removed)
    Mask.circle(position.x, position.y, support_beam_range, function(x, y, tile_distance_to_center)
        local fraction = 1
        local modifier = -1

        if (support_removed) then
            modifier = 1
        end

        if (0 ~= tile_distance_to_center) then
            fraction = tile_distance_to_center / support_beam_range
        end

        PressureMap.add(surface, {x = x, y = y}, fraction * modifier)
    end)

    if (support_removed) then
        PressureMap.process_maxed_values_buffer(surface, function ()
            require 'Diggy.Debug'.print('Cave collapsed at: ' .. position.x .. ',' .. position.y)
        end)
    end
end

--[[--
    @param config Table {@see Diggy.Config}.
    @param entity LuaEntity
    @return number the range this entity supports the cave
]]
local function get_entity_support_range(config, entity)
    for _, support_entity in pairs(config.features.DiggyCaveCollapse.support_beam_entities) do
        if (support_entity.name == entity.name) then
            return entity.range
        end
    end

    return 0
end

--[[--
    Registers all event handlers.]

    @param config Table {@see Diggy.Config}.
]]
function DiggyCaveCollapse.register(config)
    Event.add(defines.events.on_robot_built_entity, function(event)
        local range = get_entity_support_range(config, event.created_entity)

        if (0 == range) then
            return
        end

        update_pressure_map(event.created_entity.surface, {
            x = event.created_entity.position.x,
            y = event.created_entity.position.y,
        }, range, false)
    end)

    Event.add(defines.events.on_built_entity, function(event)
        local range = get_entity_support_range(config, event.created_entity)

        if (0 == range) then
            return
        end

        update_pressure_map(event.created_entity.surface, {
            x = event.created_entity.position.x,
            y = event.created_entity.position.y,
        }, range, false)
    end)

    Event.add(Template.events.on_entity_placed, function(event)
        local range = get_entity_support_range(config, event.entity)

        if (0 == range) then
            return
        end

        update_pressure_map(event.entity.surface, {
            x = event.entity.position.x,
            y = event.entity.position.y,
        }, range, false)
    end)

    Event.add(DiggyHole.events.on_out_of_map_removed, function(event)
        update_pressure_map(event.surface, {
            x = event.position.x,
            y = event.position.y,
        }, config.features.DiggyCaveCollapse.out_of_map_support_beam_range, false)
    end)

    Event.add(defines.events.on_entity_died, function(event)
        local range = get_entity_support_range(config, event.entity)

        if (0 == range) then
            return
        end

        update_pressure_map(event.surface, {
            x = event.position.x,
            y = event.position.y,
        }, range, true)
    end)

    Event.add(defines.events.on_player_mined_entity, function(event)
        local range = get_entity_support_range(config, event.entity)

        if (0 == range) then
            return
        end

        update_pressure_map(event.surface, {
            x = event.position.x,
            y = event.position.y,
        }, range, true)
    end)
end

--[[--
    Initializes the Feature.

    @param config Table {@see Diggy.Config}.
]]
function DiggyCaveCollapse.initialize(config)

end

return DiggyCaveCollapse
