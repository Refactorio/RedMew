-- Tests for the test helpers that work without a player, so headless runs (CI) can use them.
-- They run on every map, so they keep to what any map allows: a map may put tiles of its own on
-- every surface (Diggy does), and its building rules apply on scratch surfaces too.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Helper = require 'utils.test.helper'

local ROBOT_TICKS = 1800

Declare.module({'utils', 'test helper'}, function()
    Declare.test('create_test_surface makes a surface with ground everywhere and nothing on it', function(context)
        -- Act
        local surface, delete_surface = Helper.create_test_surface(context)
        context:add_teardown(delete_surface)

        -- Assert, once the surface's chunks are generated
        context:next(function()
            local area = {{-32, -32}, {32, 32}}
            Assert.equal(0, surface.count_tiles_filtered {area = area, name = 'out-of-map'}, 'void tiles')
            Assert.equal(0, surface.count_entities_filtered {area = area}, 'entities on the surface')
        end)
    end)

    Declare.test('robot_network has robots build ghosts and mine what is marked', function(context)
        -- Arrange: a pipe, as maps with building rules allow them everywhere (Danger Ores on ore,
        -- Safety Ores off ore, Concrete Jungle on bare ground)
        local surface, delete_surface = Helper.create_test_surface(context)
        context:add_teardown(delete_surface)
        local storage
        local built = {x = 10.5, y = 10.5}
        local mined = {x = -10.5, y = 10.5}
        local function pipes_built()
            return surface.count_entities_filtered {position = built, radius = 0.5, name = 'pipe'}
        end

        context:next(function()
            local remove_network
            storage, remove_network = Helper.robot_network(surface, {x = 0, y = 0}, {{name = 'pipe', count = 1}})
            context:add_teardown(remove_network)

            -- Act: a ghost to build and a chest to mine
            Assert.valid(surface.create_entity {name = 'entity-ghost', inner_name = 'pipe', position = built, force = 'player'}, 'the ghost was not placed')
            local chest = surface.create_entity {name = 'wooden-chest', position = mined, force = 'player'}
            Assert.is_true(chest.order_deconstruction('player'), 'the wooden chest was not marked')
        end):wait_until(ROBOT_TICKS, function()
            -- Assert: the robots build the pipe and bring the chest back to storage
            return pipes_built() == 1 and storage.get_item_count('wooden-chest') == 1
        end, function()
            return 'the robots did not build the ghost and mine the marked chest: pipes built ' .. pipes_built()
                .. ', wooden chests in storage ' .. storage.get_item_count('wooden-chest')
        end):next(function()
            Assert.equal(0, storage.get_item_count('pipe'), 'pipes left in storage')
        end)
    end)
end)
