-- In-game tests for every Danger Ores map. These run under _DEBUG via /test-runner, and are
-- discovered on every Danger Ores map, since they all build their map with map.lua.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local H = require 'map_gen.maps.danger_ores.modules.terrain_test_helper'
local RS = require 'map_gen.shared.redmew_surface'

-- how far from spawn every main ore has to show up; the sectors meet around spawn, so players
-- can reach each ore without leaving the starting area for long
local REACH = 256

Declare.module(
    {'map_gen', 'danger ores', 'main ores'},
    function()
        Declare.test(
            'every main ore is near spawn',
            function()
                -- Arrange: the map's main ores
                local spawn = game.forces.player.get_spawn_position(RS.get_surface())
                local names = {}
                for _, ore in pairs(DOC.map_config.main_ores) do
                    local name = ore.name
                    local prototype = name and prototypes.entity[name]
                    if prototype and prototype.type == 'resource' then
                        names[#names + 1] = name
                    end
                end
                Assert.is_true(#names > 0, 'the map has no main ores to check')

                -- Act: most maps have every ore much closer than REACH
                local missing
                H.generate_until(spawn.x, spawn.y, {64, 128, REACH}, function(surface, reach)
                    local area = {{spawn.x - reach, spawn.y - reach}, {spawn.x + reach, spawn.y + reach}}
                    missing = {}
                    for _, name in pairs(names) do
                        if surface.count_entities_filtered {area = area, name = name, limit = 1} == 0 then
                            missing[#missing + 1] = name
                        end
                    end
                    return #missing == 0
                end)

                -- Assert
                Assert.is_true(#missing == 0, 'not within ' .. REACH .. ' tiles of spawn: ' .. table.concat(missing, ', '))
            end
        )
    end
)
