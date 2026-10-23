-- In-game tests for the Archipelago overlay. These run under _DEBUG via /test-runner, and are
-- only discovered when archipelago.lua is loaded, i.e. when DO/Archipelago is the active map.
-- They check the real map, whatever its seed, generating chunks terraforming hasn't unlocked yet.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local H = require 'map_gen.maps.danger_ores.modules.terrain_test_helper'

local sea_names = {'water-mud', 'water-shallow', 'water', 'deepwater'}
local walkable = {['water-mud'] = true, ['water-shallow'] = true, ['water'] = false, ['deepwater'] = false}

-- the areas the sea tests grow through until they find what they need: every seed tried had
-- all four kinds of sea within 320 of spawn
local HALVES = {128, 192, 256, 320}

local function has_tiles(surface, half, names)
    for _, name in pairs(names) do
        if surface.count_tiles_filtered {area = {{-half, -half}, {half, half}}, name = name, limit = 1} == 0 then
            return false
        end
    end
    return true
end

Declare.module(
    {'map_gen', 'danger ores', 'archipelago'},
    function()
        local config = DOC.map_config
        local spawn_island_radius = config.archipelago_spawn_island_radius or 120

        Declare.test(
            'spawn sits on dry land apart from its pond',
            function()
                local surface = H.generate_around(0, 0, spawn_island_radius + 32)
                local wet = H.count_outside_spawn_pond(surface, spawn_island_radius - 1, sea_names)
                Assert.equal(0, wet, 'sea tiles between the spawn pond and ' .. spawn_island_radius .. ' from spawn')
            end
        )

        Declare.test(
            'coasts shade from mud and shallows into open water',
            function()
                local surface, half = H.generate_until(0, 0, HALVES, function(s, half)
                    return has_tiles(s, half, {'water', 'deepwater'})
                end)
                Assert.is_true(has_tiles(surface, half, {'water', 'deepwater'}), 'no water and deep water within ' .. half .. ' of spawn')
                local sea = H.tile_set(surface, {{-half, -half}, {half, half}}, sea_names)
                local bad, first = 0, nil
                local inner = {{-half + 1, -half + 1}, {half - 1, half - 1}}
                local pond = H.SPAWN_POND_RADIUS + 1
                for _, tile in pairs(surface.find_tiles_filtered {area = inner, name = {'water', 'deepwater'}}) do
                    local p = tile.position
                    for _, d in pairs {{1, 0}, {-1, 0}, {0, 1}, {0, -1}} do
                        if H.distance(p.x, p.y) > pond and not sea[H.key(p.x + d[1], p.y + d[2])] then
                            bad = bad + 1
                            first = first or p
                        end
                    end
                end
                Assert.equal(0, bad, 'water or deep water tiles next to land' .. (first and (', e.g. at ' .. first.x .. ',' .. first.y) or ''))
            end
        )

        Declare.test(
            'mud and shallows can be walked on, water and deep water cannot',
            function()
                -- a tile of each kind surrounded by its own kind, with nothing standing on it
                local function clear_spot(surface, half, name)
                    local same = H.tile_set(surface, {{-half, -half}, {half, half}}, name)
                    for _, tile in pairs(surface.find_tiles_filtered {area = {{-half + 1, -half + 1}, {half - 1, half - 1}}, name = name}) do
                        local p = tile.position
                        if same[H.key(p.x + 1, p.y)] and same[H.key(p.x - 1, p.y)] and same[H.key(p.x, p.y + 1)] and same[H.key(p.x, p.y - 1)]
                            and surface.count_entities_filtered {area = {{p.x - 1, p.y - 1}, {p.x + 2, p.y + 2}}} == 0 then
                            return p
                        end
                    end
                end
                local spots
                local surface, half = H.generate_until(0, 0, HALVES, function(s, half)
                    spots = {}
                    for name in pairs(walkable) do
                        spots[name] = clear_spot(s, half, name)
                        if not spots[name] then
                            return false
                        end
                    end
                    return true
                end)
                for name, expected in pairs(walkable) do
                    local spot = spots[name]
                    Assert.is_true(spot ~= nil, 'no clear ' .. name .. ' tile found within ' .. half .. ' of spawn')

                    local can = surface.can_place_entity {name = 'character', position = {spot.x + 0.5, spot.y + 0.5}, force = 'player'}
                    Assert.equal(expected, can, 'a character can stand on ' .. name .. ' at ' .. spot.x .. ',' .. spot.y)
                end
            end
        )

        Declare.test(
            'every kind of sea can be landfilled',
            function()
                local place = prototypes.item['landfill'].place_as_tile_result
                local blocked_layers = place.condition and place.condition.layers or {}
                local allowed = place.tile_condition
                for _, name in pairs(sea_names) do
                    local layers = prototypes.tile[name].collision_mask.layers
                    for layer in pairs(blocked_layers) do
                        Assert.is_true(not layers[layer], 'landfill cannot be placed on ' .. name .. ': it has the ' .. layer .. ' layer')
                    end
                    if allowed then
                        local listed = false
                        for _, tile in pairs(allowed) do
                            if (type(tile) == 'string' and tile or tile.name) == name then
                                listed = true
                            end
                        end
                        Assert.is_true(listed, 'landfill cannot be placed on ' .. name .. ': not in its tile_condition')
                    end
                end
            end
        )
    end
)
