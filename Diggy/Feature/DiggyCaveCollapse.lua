--[[-- info
    Provides the ability to collapse caves when digging.
]]

-- dependencies
require 'utils.list_utils'

local Event = require 'utils.event'
local Template = require 'Diggy.Template'
local Mask = require 'Diggy.Mask'
local PressureMap = require 'Diggy.PressureMap'

-- this
local DiggyCaveCollapse = {}

--[[--
    @param surface LuaSurface
    @param position Position with x and y
    @param strength positive increases pressure, negative decreases pressure
]]
local function update_pressure_map(surface, position, strength)
    require 'Diggy.Debug'.print(position.x .. ',' .. position.y .. ' :: update_pressure_map')
    Mask.blur(position.x, position.y, strength, function (x, y, fraction)
        PressureMap.add(surface, {x = x, y = y}, fraction)
    end)

    PressureMap.process_maxed_values_buffer(surface, function (position)
        require 'Diggy.Debug'.print('Cave collapsed at: ' .. position.x .. ',' .. position.y)
        Template.insert(surface, {{name = 'lab-dark-2', position = position}})
    end)
end

--[[--
    @param config Table {@see Diggy.Config}.
    @param entity LuaEntity
    @return number the strength this entity supports the cave
]]
local function get_entity_strength(config, entity)
    for _, support_entity in pairs(config.features.DiggyCaveCollapse.support_beam_entities) do
        if (support_entity.name == entity.name) then
            return support_entity.strength
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
        local strength = get_entity_strength(config, event.created_entity)

        if (0 == strength) then
            return
        end

        update_pressure_map(event.created_entity.surface, {
            x = event.created_entity.position.x,
            y = event.created_entity.position.y,
        }, -1 * strength)
    end)

    Event.add(defines.events.on_built_entity, function(event)
        local strength = get_entity_strength(config, event.created_entity)

        if (0 == strength) then
            return
        end

        update_pressure_map(event.created_entity.surface, {
            x = event.created_entity.position.x,
            y = event.created_entity.position.y,
        }, -1 * strength)
    end)

    Event.add(Template.events.on_placed_entity, function(event)
        local strength = get_entity_strength(config, event.entity)

        if (0 == strength) then
            return
        end

        update_pressure_map(event.entity.surface, {
            x = event.entity.position.x,
            y = event.entity.position.y,
        }, -1 * strength)
    end)

    Event.add(defines.events.on_entity_died, function(event)
        local strength = get_entity_strength(config, event.entity)

        if (0 == strength) then
            return
        end

        update_pressure_map(event.entity.surface, {
            x = event.entity.position.x,
            y = event.entity.position.y,
        }, strength)
    end)

    Event.add(defines.events.on_player_mined_entity, function(event)
        local strength = get_entity_strength(config, event.entity)

        if (0 == strength) then
            return
        end

        update_pressure_map(event.entity.surface, {
            x = event.entity.position.x,
            y = event.entity.position.y,
        }, strength)
    end)
end

--[[--
    Initializes the Feature.

    @param config Table {@see Diggy.Config}.
]]
function DiggyCaveCollapse.initialize(config)

end

return DiggyCaveCollapse
