-- In-game tests for the Danger Ores win condition. These run under _DEBUG via /test-runner on
-- every Danger Ores map with rocket_launched enabled: the first satellite kills all the
-- biters, and win_satellite_count satellites win the map.
--
-- A real launch needs a working silo and a long countdown, so the test raises the launch
-- event the way Factorio would, with a stand-in rocket whose cargo pod is a chest of
-- satellites. Satellites are counted from the event (utils/rocket), so the counts it leaves
-- behind, a killed enemy force and a won map stay on the save it runs on.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Helper = require 'utils.test.helper'
local EventFactory = require 'utils.test.event_factory'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local Rocket = require 'utils.rocket'
local RS = require 'map_gen.shared.redmew_surface'
local ShareGlobals = require 'map_gen.maps.danger_ores.modules.shared_globals'
local H = require 'map_gen.maps.danger_ores.modules.terrain_test_helper'

local config = DOC.rocket_launched
if not config.enabled then
    return
end

local WIN = config.win_satellite_count or 1000
local QUALITY = config.win_satellite_quality

-- somewhere away from spawn and from what the other tests generate
local SPOT = {x = 64, y = -96}

local function satellites_launched()
    return Rocket.get_item_launched {name = 'satellite', force = 'player', quality = QUALITY, comparator = '>='}
end

-- Launches `count` satellites in stand-in rockets: as many as it takes, since a satellite
-- doesn't stack and a chest only holds so many.
local function launch(surface, count)
    while count > 0 do
        local chest = surface.create_entity {name = 'steel-chest', position = {SPOT.x + 0.5, SPOT.y + 0.5}, force = 'player'}
        Assert.valid(chest, 'the stand-in cargo pod was not created')
        local loaded = chest.insert {name = 'satellite', count = count, quality = QUALITY}
        Assert.is_true(loaded > 0, 'no satellites fit in the stand-in cargo pod')
        local rocket = Helper.fake_lua_object(chest, {cargo_pod = chest})
        EventFactory.raise {name = defines.events.on_rocket_launched, tick = game.tick, rocket = rocket}
        chest.destroy()
        count = count - loaded
    end
end

Declare.module(
    {'map_gen', 'danger ores', 'win condition'},
    function()
        Declare.test(
            'the first satellite kills the biters, and ' .. WIN .. ' win the map',
            function(context)
                -- Arrange
                Assert.equal(0, satellites_launched(), 'satellites were already launched on this save')
                Assert.is_true(not ShareGlobals.data.map_won, 'the map was already won')

                local surface = H.generate_around(SPOT.x, SPOT.y, 32)
                local spawner = surface.create_entity {name = 'biter-spawner', position = {SPOT.x + 12, SPOT.y}, force = 'enemy'}
                local biter = surface.create_entity {name = 'small-biter', position = {SPOT.x - 12, SPOT.y}, force = 'enemy'}
                Assert.valid(spawner, 'the test spawner was not created')
                Assert.valid(biter, 'the test biter was not created')

                -- Act: the first satellite
                launch(surface, 1)

                -- Assert
                Assert.equal(1, satellites_launched(), 'satellites counted after the first launch')
                Assert.is_true(ShareGlobals.data.biters_disabled, 'the first satellite did not disable the biters')
                Assert.equal(0, RS.get_surface().count_entities_filtered {force = 'enemy'}, 'enemies left after the first satellite')
                Assert.is_true(not ShareGlobals.data.map_won, 'the map was won after one satellite')

                context:next(function()
                    -- Act: one short of the win
                    launch(surface, WIN - 2)

                    -- Assert
                    Assert.equal(WIN - 1, satellites_launched(), 'satellites counted one short of the win')
                    Assert.is_true(not ShareGlobals.data.map_won, 'the map was won one satellite short')

                    -- Act: the last one
                    launch(surface, 1)

                    -- Assert
                    Assert.equal(WIN, satellites_launched(), 'satellites counted at the win')
                    Assert.is_true(ShareGlobals.data.map_won, 'the map was not won at ' .. WIN .. ' satellites')
                end)
            end
        )
    end
)
