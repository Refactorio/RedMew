--[[-- info
    Provides the ability to "mine" through out-of-map tiles by destroying or
    mining rocks next to it.
]]

-- dependencies
local Event = require 'utils.event'
local Scanner = require 'map_gen.Diggy.Scanner'
local Template = require 'map_gen.Diggy.Template'
local Debug = require 'map_gen.Diggy.Debug'
local insert = table.insert
local random = math.random

-- this
local DiggyHole = {}

--[[--
    Triggers a diggy diggy hole for a given sand-rock-big.

    Will return true even if the tile behind it is immune.

    @param entity LuaEntity
]]
local function diggy_hole(entity)
    if (entity.name ~= 'sand-rock-big') then
        return
    end

    local tiles = {}
    local rocks = {}
    local surface = entity.surface

    local out_of_map_found = Scanner.scan_around_position(surface, entity.position, 'out-of-map');

    for _, position in pairs(out_of_map_found) do
        insert(tiles, {name = 'dirt-' .. random(1, 7), position = position})
        insert(rocks, {name = 'sand-rock-big', position = position})
    end

    Template.insert(surface, tiles, rocks)
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

local function on_mined_tile(surface, tiles)
    local new_tiles = {}

    for _, tile in pairs(tiles) do
        if (artificial_tiles[tile.old_tile.name]) then
            insert(new_tiles, { name = 'dirt-' .. random(1, 7), position = tile.position})
        end
    end

    Template.insert(surface, new_tiles, {})
end

local function on_built_tile(surface, item, old_tile_and_positions)
    if ('landfill' ~= item.name) then
        return
    end

    local tiles = {}
    for _, tile in pairs(old_tile_and_positions) do
        insert(tiles, {name = 'dirt-' .. random(1, 7), position = tile.position})
    end

    Template.insert(surface, tiles)
end

--[[--
    Registers all event handlers.
]]
function DiggyHole.register(config)
    Event.add(defines.events.on_entity_died, function (event)
        diggy_hole(event.entity)
    end)

    Event.add(defines.events.on_player_mined_entity, function (event)
        diggy_hole(event.entity)
    end)

    Event.add(defines.events.on_robot_mined_tile, function(event)
        on_mined_tile(event.robot.surface, event.tiles)
    end)

    Event.add(defines.events.on_player_mined_tile, function(event)
        on_mined_tile(game.surfaces[event.surface_index], event.tiles)
    end)

    Event.add(defines.events.on_robot_built_tile, function (event)
        on_built_tile(event.robot.surface, item, tiles)
    end)

    Event.add(defines.events.on_player_built_tile, function (event)
        on_built_tile(game.surfaces[event.surface_index], event.item, event.tiles)
    end)
end

function DiggyHole.on_init()
    game.forces.player.technologies['landfill'].enabled = false
end

return DiggyHole
