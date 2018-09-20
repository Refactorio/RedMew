--[[-- info
    Provides the ability to collapse caves when digging.
]]

-- dependencies
require 'utils.list_utils'

local Event = require 'utils.event'
local Template = require 'map_gen.Diggy.Template'
local Mask = require 'map_gen.Diggy.Mask'
local StressMap = require 'map_gen.Diggy.StressMap'
local Debug = require'map_gen.Diggy.Debug'

-- this
local DiggyCaveCollapse = {}

global.DiggyCaveCollapse = {}
global.DiggyCaveCollapse.triggers = {}


DiggyCaveCollapse.events = {
    --[[--
        When stress at certain position is above the collapse threshold
         - position LuaPosition
         - surface LuaSurface
    ]]
    on_collapse_triggered = script.generate_event_name()
}


local function create_collapse_template(positions, surface)
    local entities = {}
    local tiles = {}
    for _, position in pairs(positions) do
        table.insert(entities, {position = {x = position.x, y = position.y - 1}, name = 'sand-rock-big'})
        table.insert(entities, {position = {x = position.x + 1, y = position.y}, name = 'sand-rock-big'})
        table.insert(entities, {position = {x = position.x, y = position.y + 1}, name = 'sand-rock-big'})
        table.insert(entities, {position = {x = position.x - 1, y = position.y}, name = 'sand-rock-big'})
        table.insert(tiles, {position = {x = position.x, y = position.y}, name = 'out-of-map'})
    end
    for _, new_spawn in pairs({entities, tiles}) do
        for _, tile in pairs(new_spawn) do
            for _, entity in pairs(surface.find_entities_filtered({position = tile.position})) do
                pcall(function() entity.die() end)
                pcall(function() entity.destroy() end)
            end
        end
    end
    for key,entity in pairs(entities) do
      if not entity.valid then
        entities[key] = nil
      end
    end
    return tiles, entities
end

--[[--
    @param surface LuaSurface
    @param position Position with x and y
    @param strength positive increases stress, negative decreases stress
]]
local function update_stress_map(surface, position, strength)
    local  max_value
    Mask.blur(position.x, position.y, strength, function (x, y, fraction)
        max_value = StressMap.add(surface, {x = x, y = y}, fraction)
    end)


    if max_value then
        script.raise_event(DiggyCaveCollapse.events.on_collapse_triggered, {surface = surface, position = position})
    end
end

local function collapse(surface, position)
  local positions = {}

  Mask.blur(position.x, position.y, 10, function(x,y, value)
      StressMap.check_stress_in_threshold(surface, {x=x,y=y}, value, function(_, position)
          table.insert(positions, position)
      end)

    end)
    local tiles, entities = create_collapse_template(positions, surface)
    Template.insert(surface, tiles, entities)
end


--[[--
    Registers all event handlers.]

    @param config Table {@see Diggy.Config}.
]]
function DiggyCaveCollapse.register(config)
    local support_beam_entities = config.features.DiggyCaveCollapse.support_beam_entities;

    Event.add(DiggyCaveCollapse.events.on_collapse_triggered, function(event)
        -- TODO: Add time delay here
        collapse(event.surface,  event.position)
    end)

    Event.add(defines.events.on_robot_built_entity, function(event)
        local strength = support_beam_entities[event.created_entity.name]

        if (not strength) then
            return
        end

        update_stress_map(event.created_entity.surface, {
            x = event.created_entity.position.x,
            y = event.created_entity.position.y,
        }, -1 * strength)
    end)

    Event.add(defines.events.on_built_entity, function(event)
        local strength = support_beam_entities[event.created_entity.name]


        if (not strength) then
            return
        end

        update_stress_map(event.created_entity.surface, {
            x = event.created_entity.position.x,
            y = event.created_entity.position.y,
        }, -1 * strength)
    end)

    Event.add(Template.events.on_placed_entity, function(event)
        local strength = support_beam_entities[event.entity.name]


        if (not strength) then
            return
        end

        update_stress_map(event.entity.surface, {
            x = event.entity.position.x,
            y = event.entity.position.y,
        }, -1 * strength)
    end)

    Event.add(defines.events.on_entity_died, function(event)
        local strength = support_beam_entities[event.entity.name]

        if (not strength) then
            return
        end

        update_stress_map(event.entity.surface, {
            x = event.entity.position.x,
            y = event.entity.position.y,
        }, strength)
    end)

    Event.add(defines.events.on_player_mined_entity, function(event)
        local strength = support_beam_entities[event.entity.name]

        if (not strength) then
            return
        end

        update_stress_map(event.entity.surface, {
            x = event.entity.position.x,
            y = event.entity.position.y,
        }, strength)
    end)

    Event.add(Template.events.on_void_removed, function(event)
        local strength = support_beam_entities['out-of-map']

        update_stress_map(event.surface, {
            x = event.old_tile.position.x,
            y = event.old_tile.position.y,
        }, strength)
    end)

    Event.add(Template.events.on_void_added, function(event)
        local strength = support_beam_entities['out-of-map']

        update_stress_map(event.surface, {
            x = event.old_tile.position.x,
            y = event.old_tile.position.y,
        }, -1  * strength)
    end)
end

--[[--
    Initializes the Feature.

    @param config Table {@see Diggy.Config}.
]]
function DiggyCaveCollapse.initialize(config)

end

return DiggyCaveCollapse
