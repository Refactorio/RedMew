-- In-game tests for the Danger Ores Space Age win condition. These run under _DEBUG via
-- /test-runner on the Space Age preset: a rocket launch tells players the goal, crafting a
-- legendary mech armor wins the map, and a normal one doesn't.
--
-- Crafting is read from the player force's production statistics, so the test records mech
-- armor there the way crafting it would. The won map stays on the save it runs on.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local EventFactory = require 'utils.test.event_factory'
local RS = require 'map_gen.shared.redmew_surface'
local ShareGlobals = require 'map_gen.maps.danger_ores.modules.shared_globals'

local CHECK_TICKS = 301 -- how often the win is checked

Declare.module(
    {'map_gen', 'danger ores', 'space age win condition'},
    function()
        local function craft(quality)
            game.forces.player.get_item_production_statistics(RS.get_surface()).on_flow({name = 'mech-armor', quality = quality}, 1)
        end

        Declare.test(
            'a legendary mech armor wins the map, a normal one does not',
            function(context)
                -- Arrange
                Assert.is_true(not ShareGlobals.data.map_won, 'the map was already won')

                -- Act: a rocket launch only tells players the goal
                EventFactory.raise {name = defines.events.on_rocket_launched, tick = game.tick}

                -- Assert
                Assert.is_true(ShareGlobals.data.goal_notice, 'a rocket launch did not tell players the goal')
                Assert.is_true(not ShareGlobals.data.map_won, 'a rocket launch won the map')

                -- Act: a normal mech armor
                craft('normal')
                context:timeout(CHECK_TICKS + 10, function()
                    -- Assert
                    Assert.is_true(not ShareGlobals.data.map_won, 'a normal mech armor won the map')

                    -- Act: a legendary one
                    craft('legendary')
                    context:timeout(CHECK_TICKS + 10, function()
                        -- Assert
                        Assert.is_true(ShareGlobals.data.map_won, 'a legendary mech armor did not win the map')
                    end)
                end)
            end
        )
    end
)
