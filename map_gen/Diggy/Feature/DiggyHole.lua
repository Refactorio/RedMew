--[[-- info
    Provides the ability to "mine" through out-of-map tiles by destroying or
    mining rocks next to it.
]]

-- dependencies
local Event = require 'utils.event'
local Scanner = require 'map_gen.Diggy.Scanner'
local Template = require 'map_gen.Diggy.Template'

-- this
local DiggyHole = {}

--[[--
    Triggers a diggy diggy hole for a given sand-rock-big.

    Will return true even if the tile behind it is immune.

    @param entity LuaEntity
    @param temporary_inventory LuaInventory
]]
local function diggy_hole(entity, temporary_inventory)
    if (entity.name ~= 'sand-rock-big') then
        return
    end

    -- prevent the mined ore from reaching the inventory
    if (nil ~= temporary_inventory) then
        temporary_inventory.clear()
    end

    local tiles = {}
    local rocks = {}

    local out_of_map_found = Scanner.scan_around_position(entity.surface, entity.position, 'out-of-map');

    for _, position in pairs(out_of_map_found) do
        table.insert(tiles, {name = 'dirt-' .. math.random(1, 7), position = {x = position.x, y = position.y}})
        table.insert(rocks, {name = 'sand-rock-big', position = {x = position.x, y = position.y}})
    end

    Template.insert(entity.surface, tiles, rocks, true)
end

local artificial_tiles = {
    ['stone-brick'] = true,
    ['stone-path'] = true,
    ['concrete'] = true,
    ['hazard-concrete-left'] = true,
    ['hazard-concrete-right'] = true,
    ['refined-concrete'] = true,
    ['refined-hazard-concrete-left'] = true,
    ['refined-hazard-concrete-right'] = true,
}

--[[--
    Registers all event handlers.
]]
function DiggyHole.register(config)
    Event.add(defines.events.on_entity_died, function (event)
        diggy_hole(event.entity)
    end)

    Event.add(defines.events.on_player_mined_entity, function (event)
        diggy_hole(event.entity, event.buffer)
    end)

    Event.add(defines.events.on_marked_for_deconstruction, function (event)
        if ('sand-rock-big' == event.entity.name) then
            event.entity.cancel_deconstruction(game.players[event.player_index].force)
        end
    end)

    Event.add(defines.events.on_robot_mined_tile, function(event)
        local tiles = {}

        for _, tile in pairs(event.tiles) do
            if (artificial_tiles[tile.old_tile.name]) then
                table.insert(tiles, {name = 'dirt-' .. math.random(1, 7), position = tile.position})
            end
        end

        Template.insert(event.robot.surface, tiles, {})
    end)

    Event.add(defines.events.on_player_mined_tile, function(event)
        local tiles = {}

        for _, tile in pairs(event.tiles) do
            if (artificial_tiles[tile.old_tile.name]) then
                table.insert(tiles, {name = 'dirt-' .. math.random(1, 7), position = tile.position})
            end
        end

        Template.insert(game.surfaces[event.surface_index], tiles, {})
    end)
end

--[[--
    Initializes the Feature.

    @param config Table {@see Diggy.Config}.
]]
function DiggyHole.initialize(config)

end

return DiggyHole
