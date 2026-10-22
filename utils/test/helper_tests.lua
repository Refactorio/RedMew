-- Tests for the test helpers that work without a player, so headless runs (CI) can use them.
-- They run on every map, so they keep to what any map allows: a map may put tiles of its own on
-- every surface (Diggy does), and its building rules apply on scratch surfaces too.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Helper = require 'utils.test.helper'

local ROBOT_TICKS = 1800

Declare.module({'utils', 'test helper'}, function()
    Declare.test('create_test_surface makes a surface with ground everywhere and nothing on it', function(context)
        local surface, delete_surface = Helper.create_test_surface(context)
        context:add_teardown(delete_surface)

        context:next(function()
            local area = {{-32, -32}, {32, 32}}
            Assert.equal(0, surface.count_tiles_filtered {area = area, name = 'out-of-map'}, 'void tiles')
            Assert.equal(0, surface.count_entities_filtered {area = area}, 'entities on the surface')
        end)
    end)

    Declare.test('robot_network has robots build ghosts and mine what is marked', function(context)
        local surface, delete_surface = Helper.create_test_surface(context)
        context:add_teardown(delete_surface)

        -- a pipe, as maps with building rules allow them everywhere (Danger Ores on ore, Safety
        -- Ores off ore, Concrete Jungle on bare ground)
        local storage
        local built = {x = 10.5, y = 10.5}
        local mined = {x = -10.5, y = 10.5}
        context:next(function()
            local remove_network
            storage, remove_network = Helper.robot_network(surface, {x = 0, y = 0}, {{name = 'pipe', count = 1}})
            context:add_teardown(remove_network)

            Assert.valid(surface.create_entity {name = 'entity-ghost', inner_name = 'pipe', position = built, force = 'player'}, 'the ghost was not placed')
            local chest = surface.create_entity {name = 'wooden-chest', position = mined, force = 'player'}
            Assert.is_true(chest.order_deconstruction('player'), 'the wooden chest was not marked')

            Helper.wait_until(context, ROBOT_TICKS, function()
                return surface.count_entities_filtered {position = built, radius = 0.5, name = 'pipe'} == 1
                    and storage.get_item_count('wooden-chest') == 1
            end, function(ok)
                Assert.is_true(ok, 'the robots did not build the ghost and mine the marked chest: pipes built '
                    .. surface.count_entities_filtered {position = built, radius = 0.5, name = 'pipe'}
                    .. ', wooden chests in storage ' .. storage.get_item_count('wooden-chest'))
                Assert.equal(0, storage.get_item_count('pipe'), 'pipes left in storage')
            end)
        end)
    end)
end)
