-- In-game tests for autodeconstruct. These run on every map with it enabled (the default): a
-- mining drill whose ore runs out puts out its last ore, is marked for deconstruction, and real
-- construction robots take it back to storage.
--
-- They are under map_gen in the test tree so the headless runs (utils/test/headless.lua) pick
-- them up. A burner drill on a scratch surface keeps them independent of the map's ore and power.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Helper = require 'utils.test.helper'

local DRILL = 'burner-mining-drill'
local ORE_AMOUNT = 1

Declare.module(
    {'map_gen', 'autodeconstruct'},
    function()
        Declare.test(
            'a drill whose ore runs out puts out the last ore and goes back to storage',
            function(context)
                -- Arrange: a drill on a little ore, fuelled, with a chest for its output and
                -- robots to take it away
                local surface, delete_surface = Helper.create_test_surface(context)
                context:add_teardown(delete_surface)

                local storage, ore, drill, chest

                context:timeout(2, function()
                    local remove_network
                    storage, remove_network = Helper.robot_network(surface, {x = 0, y = 0})
                    context:add_teardown(remove_network)
                    ore = surface.create_entity {name = 'iron-ore', position = {12.5, 12.5}, amount = ORE_AMOUNT}
                    drill = surface.create_entity {name = DRILL, position = {13, 13}, force = 'player'}
                    Assert.valid(drill, 'the test drill was not built')
                    chest = surface.create_entity {name = 'iron-chest', position = drill.drop_position, force = 'player'}
                    Assert.valid(chest, 'the chest at the drill output was not built')

                    -- Act: fuel it, and let it mine the ore out
                    drill.insert {name = 'coal', count = 5}
                end):wait_until(3600, function()
                    return not drill.valid and storage.get_item_count(DRILL) == 1
                end, function()
                    return 'the drill on mined out ore did not come back to storage: ore left ' .. tostring(ore.valid) .. ', drill still there ' .. tostring(drill.valid) .. ', marked ' .. tostring(drill.valid and drill.to_be_deconstructed())
                end):next(function()
                    -- Assert
                    Assert.is_true(not ore.valid, 'the ore was not mined out')
                    Assert.equal(ORE_AMOUNT, chest.get_item_count('iron-ore'), 'ore put out before the drill was taken away')
                end)
            end
        )
    end
)
