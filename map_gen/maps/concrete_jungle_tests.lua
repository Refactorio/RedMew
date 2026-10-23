-- In-game tests for Concrete Jungle. These run when it is the active map: a building needs
-- floor of its tier under it (stone path for most), so one built on bare ground is removed and
-- handed back, as is one robots upgrade to on a floor it doesn't allow, and laying a lower
-- floor over a higher one puts the higher one back and hands the lower one back.
--
-- Real construction robots build on a scratch surface, so the game runs its own build events
-- and the robots take back to storage whatever they are handed.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Helper = require 'utils.test.helper'

local BUILDING = 'iron-chest' -- needs stone path
local ROBOT_TICKS = 1800

Declare.module(
    {'map_gen', 'concrete jungle'},
    function()
        local surface, delete_surface
        local storage, remove_network

        Declare.module_startup(
            function(context)
                surface, delete_surface = Helper.create_test_surface(context)
                context:next(function()
                    storage, remove_network = Helper.robot_network(surface, {x = 0, y = 0})
                end)
            end
        )

        Declare.module_teardown(
            function()
                remove_network()
                delete_surface()
            end
        )

        local function in_storage(name)
            return storage.get_item_count(name)
        end

        local function chests_at(p)
            return surface.count_entities_filtered {area = {{p.x - 0.5, p.y - 0.5}, {p.x + 0.5, p.y + 0.5}}, name = BUILDING}
        end

        Declare.test(
            'a building robots build on bare ground is removed and goes back to storage',
            function(context)
                -- Arrange
                local p = {x = 12.5, y = 12.5}
                storage.insert {name = BUILDING, count = 1}

                -- Act: a ghost for the robots to build
                Assert.valid(surface.create_entity {name = 'entity-ghost', inner_name = BUILDING, position = p, force = 'player'}, 'the ghost was not placed')

                -- Assert: the robot takes the chest out of storage, builds it, and the chest is
                -- removed
                Helper.wait_until(context, ROBOT_TICKS, function()
                    return surface.count_entities_filtered {position = p, radius = 0.5, name = 'entity-ghost'} == 0 and in_storage(BUILDING) == 1
                end, function(ok)
                    Assert.equal(0, chests_at(p), BUILDING .. 's on bare ground')
                    Assert.is_true(ok, 'the ' .. BUILDING .. ' built on bare ground did not come back to storage: ' .. in_storage(BUILDING) .. ' there')
                    storage.remove_item {name = BUILDING, count = 1}
                end)
            end
        )

        Declare.test(
            'a building robots build on stone path stays',
            function(context)
                -- Arrange
                local p = {x = 14.5, y = 12.5}
                surface.set_tiles {{name = 'stone-path', position = p}}
                storage.insert {name = BUILDING, count = 1}

                -- Act: a ghost for the robots to build
                Assert.valid(surface.create_entity {name = 'entity-ghost', inner_name = BUILDING, position = p, force = 'player'}, 'the ghost was not placed')

                -- Assert
                Helper.wait_until(context, ROBOT_TICKS, function()
                    return chests_at(p) == 1
                end, function(ok)
                    Assert.is_true(ok, 'no ' .. BUILDING .. ' stood on stone path')
                    context:timeout(60, function()
                        Assert.equal(1, chests_at(p), BUILDING .. 's on stone path a second later')
                    end)
                end)
            end
        )

        Declare.test(
            'an upgrade robots make to a building the floor does not allow is undone and both go back to storage',
            function(context)
                -- Arrange: ordering an upgrade isn't checked, so the upgrade planner gets a steel
                -- furnace, which needs concrete, built over a stone furnace on stone path. The rule
                -- removes it once the robots have built it.
                local p = {x = 19, y = 13}
                surface.set_tiles {
                    {name = 'stone-path', position = {18, 12}}, {name = 'stone-path', position = {19, 12}},
                    {name = 'stone-path', position = {18, 13}}, {name = 'stone-path', position = {19, 13}}
                }
                local furnace = surface.create_entity {name = 'stone-furnace', position = p, force = 'player'}
                Assert.valid(furnace, 'the stone furnace was not created')
                storage.insert {name = 'steel-furnace', count = 1}

                -- Act
                Assert.is_true(furnace.order_upgrade {target = 'steel-furnace', force = 'player'}, 'the upgrade was not ordered')

                -- Assert
                local function furnaces()
                    return surface.count_entities_filtered {position = p, radius = 0.5, type = 'furnace'}
                end
                Helper.wait_until(context, ROBOT_TICKS, function()
                    return furnaces() == 0 and in_storage('steel-furnace') == 1 and in_storage('stone-furnace') == 1
                end, function(ok)
                    local summary = 'furnaces there ' .. furnaces() .. ', steel furnaces in storage ' .. in_storage('steel-furnace') .. ', stone furnaces in storage ' .. in_storage('stone-furnace')
                    Assert.is_true(ok, 'the upgrade was not undone with both furnaces back in storage: ' .. summary)
                    storage.remove_item {name = 'steel-furnace', count = 1}
                    storage.remove_item {name = 'stone-furnace', count = 1}
                end)
            end
        )

        Declare.test(
            'stone path robots lay over concrete is undone and the stone brick goes back to storage',
            function(context)
                -- Arrange
                local p = {x = 16, y = 12}
                surface.set_tiles {{name = 'concrete', position = p}}
                storage.insert {name = 'stone-brick', count = 1}

                -- Act: a ghost for the robots to build
                Assert.valid(surface.create_entity {name = 'tile-ghost', inner_name = 'stone-path', position = p, force = 'player'}, 'the ghost was not placed')

                -- Assert
                Helper.wait_until(context, ROBOT_TICKS, function()
                    return surface.count_entities_filtered {position = {p.x + 0.5, p.y + 0.5}, radius = 0.5, name = 'tile-ghost'} == 0 and in_storage('stone-brick') == 1
                end, function(ok)
                    local summary = 'tile ' .. surface.get_tile(p.x, p.y).name .. ', stone brick in storage ' .. in_storage('stone-brick') .. ', concrete in storage ' .. in_storage('concrete')
                    Assert.is_true(ok, 'the stone brick did not come back to storage: ' .. summary)
                    Assert.equal('concrete', surface.get_tile(p.x, p.y).name, 'tile after stone path was laid over concrete')
                    context:timeout(120, function()
                        Assert.equal(0, in_storage('concrete'), 'concrete in storage, which had none: ' .. summary)
                        Assert.equal(1, in_storage('stone-brick'), 'stone brick in storage a while later: ' .. summary)
                    end)
                end)
            end
        )
    end
)
