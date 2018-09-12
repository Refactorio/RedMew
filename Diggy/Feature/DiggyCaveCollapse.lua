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
    Mask.blur(position.x, position.y, strength, function (x, y, fraction)
        PressureMap.add(surface, {x = x, y = y}, fraction)
    end)

    PressureMap.process_maxed_values_buffer(surface, function (positions)
        local entities = {}
        local tiles = {}

        for _, position in pairs(positions) do
            local center = {x = position.x, y = position.y}
            local north = {x = position.x, y = position.y - 1}
            local east = {x = position.x + 1, y = position.y}
            local south = {x = position.x, y = position.y + 1}
            local west = {x = position.x - 1, y = position.y}
            entities[north.x .. ',' .. north.y] = {position = north, name = 'sand-rock-big'}
            entities[east.x .. ',' .. east.y] = {position = east, name = 'sand-rock-big'}
            entities[south.x .. ',' .. south.y] = {position = south, name = 'sand-rock-big'}
            entities[west.x .. ',' .. west.y] = {position = west, name = 'sand-rock-big'}
            tiles[center.x .. ',' .. center.y] = {position = center, name = 'out-of-map'}
        end

        Template.insert(surface, tiles, entities)
    end)
end

--[[--
    Registers all event handlers.]

    @param config Table {@see Diggy.Config}.
]]
function DiggyCaveCollapse.register(config)
    local support_beam_entities = config.features.DiggyCaveCollapse.support_beam_entities;

    Event.add(defines.events.on_robot_built_entity, function(event)
        local strength = support_beam_entities[event.created_entity.name]

        if (not strength) then
            return
        end

        update_pressure_map(event.created_entity.surface, {
            x = event.created_entity.position.x,
            y = event.created_entity.position.y,
        }, -1 * strength)
    end)

    Event.add(defines.events.on_built_entity, function(event)
        local strength = support_beam_entities[event.created_entity.name]

        if (not strength) then
            return
        end

        update_pressure_map(event.created_entity.surface, {
            x = event.created_entity.position.x,
            y = event.created_entity.position.y,
        }, -1 * strength)
    end)

    Event.add(Template.events.on_placed_entity, function(event)
        local strength = support_beam_entities[event.entity.name]

        if (not strength) then
            return
        end

        update_pressure_map(event.entity.surface, {
            x = event.entity.position.x,
            y = event.entity.position.y,
        }, -1 * strength)
    end)

    Event.add(defines.events.on_entity_died, function(event)
        local strength = support_beam_entities[event.entity.name]

        if (not strength) then
            return
        end

        update_pressure_map(event.entity.surface, {
            x = event.entity.position.x,
            y = event.entity.position.y,
        }, strength)
    end)

    Event.add(defines.events.on_player_mined_entity, function(event)
        local strength = support_beam_entities[event.entity.name]

        if (not strength) then
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
