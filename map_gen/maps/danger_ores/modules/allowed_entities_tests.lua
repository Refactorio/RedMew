-- In-game tests for the Danger Ores building rule. These run on every Danger Ores map with it
-- enabled (the default): a building that isn't allowed on ore is removed when built on ore, its
-- item handed back and its contents spilled, while the same building off ore, and the allowed
-- ones (belts, drills, poles...) on ore, stay.
--
-- They build on the real map's ore and raise the build event the way Factorio would. Refunds
-- go to the builder, so the buildings are "built" by a stand-in construction robot whose
-- cargo captures what it gets back: a player only exists in a real game. One
-- building is built by real robots from a ghost, so the game's own build event and refund run
-- too.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Helper = require 'utils.test.helper'
local EventFactory = require 'utils.test.event_factory'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local AllowedEntities = require 'map_gen.maps.danger_ores.modules.allowed_entities'
local H = require 'map_gen.maps.danger_ores.modules.terrain_test_helper'
local RS = require 'map_gen.shared.redmew_surface'

local config = DOC.allowed_entities
if not config.enabled then
    return
end

local BUILDING = 'iron-chest'
local ALLOWED = {'transport-belt', 'electric-mining-drill', 'small-electric-pole', 'pipe'}

Declare.module(
    {'map_gen', 'danger ores', 'allowed entities'},
    function()
        local robot

        Declare.module_startup(
            function()
                local surface = RS.get_surface()
                local p = H.dry_spot(surface, 'construction-robot') or {x = 0, y = 0}
                robot = surface.create_entity {name = 'construction-robot', position = p, force = 'player'}
            end
        )

        Declare.module_teardown(
            function()
                if robot and robot.valid then
                    robot.destroy()
                end
            end
        )

        -- Raises the robot build event for `entity`. @return what the robot got back, if anything
        local function robot_builds(entity)
            local refunded
            local fake_robot = Helper.fake_lua_object(robot, {
                valid = true,
                -- a building robot is always in a network, here one run by a roboport, and the
                -- refund goes into its cargo
                logistic_network = {
                    cells = {{owner = {name = 'roboport'}}}
                },
                get_inventory = function()
                    return {
                        insert = function(stack)
                            refunded = stack
                            return stack.count or 1
                        end
                    }
                end
            })
            EventFactory.raise {name = defines.events.on_robot_built_entity, tick = game.tick, robot = fake_robot, entity = entity}
            return refunded
        end

        local function build(surface, name, p, options)
            local spec = {name = name, position = p, force = 'player'}
            for k, v in pairs(options or {}) do
                spec[k] = v
            end
            local entity = surface.create_entity(spec)
            Assert.valid(entity, 'the test ' .. name .. ' was not created')
            return entity
        end

        Declare.test(
            'a building on ore is removed, handed back and its contents spilled',
            function()
                -- Arrange
                local surface = RS.get_surface()
                local p = H.ore_spot(surface, BUILDING)
                Assert.is_true(p ~= nil, 'no ore near spawn to build on')
                local chest = build(surface, BUILDING, p)
                Assert.is_true(not AllowedEntities.is_allowed(chest), BUILDING .. ' is allowed on ore here, so this test proves nothing')
                chest.insert {name = 'iron-plate', count = 10}
                local near = {position = p, radius = 6, name = 'item-on-ground'}
                local before = surface.count_entities_filtered(near)

                -- Act
                local refunded = robot_builds(chest)

                -- Assert
                Assert.is_true(not chest.valid, 'the ' .. BUILDING .. ' built on ore at ' .. p.x .. ',' .. p.y .. ' is still there')
                Assert.is_true(refunded ~= nil, 'nothing was handed back')
                Assert.equal(BUILDING, refunded.name, 'item handed back')
                Assert.equal(1, refunded.count, 'items handed back')
                Assert.equal(10, surface.count_entities_filtered(near) - before, 'iron plates spilled from the chest')
            end
        )

        Declare.test(
            'the same building off ore stays',
            function()
                -- Arrange
                local surface = RS.get_surface()
                local p = H.dry_spot(surface, BUILDING)
                Assert.is_true(p ~= nil, 'no ore-free ground near spawn')
                local chest = build(surface, BUILDING, p)

                -- Act
                local refunded = robot_builds(chest)

                -- Assert
                Assert.is_true(chest.valid, 'the ' .. BUILDING .. ' built off ore at ' .. p.x .. ',' .. p.y .. ' was removed')
                Assert.is_true(refunded == nil, 'something was handed back')
                chest.destroy()
            end
        )

        Declare.test(
            'belts, drills, poles and pipes stay on ore',
            function()
                local surface = RS.get_surface()
                for _, name in pairs(ALLOWED) do
                    -- Arrange
                    local p = H.ore_spot(surface, name)
                    Assert.is_true(p ~= nil, 'no ore near spawn to build a ' .. name .. ' on')
                    local entity = build(surface, name, p)

                    -- Act
                    robot_builds(entity)

                    -- Assert
                    Assert.is_true(entity.valid, 'the ' .. name .. ' built on ore at ' .. p.x .. ',' .. p.y .. ' was removed')
                    entity.destroy()
                end
            end
        )

        Declare.test(
            'a building real robots build on ore goes back to storage',
            function(context)
                -- Arrange
                local surface = RS.get_surface()
                local p = H.ore_spot(surface, BUILDING)
                Assert.is_true(p ~= nil, 'no ore near spawn to build on')
                local storage, remove_network = Helper.robot_network(surface, {x = p.x + 8, y = p.y}, {{name = BUILDING, count = 1}})
                context:add_teardown(remove_network)
                local area = {{p.x - 1, p.y - 1}, {p.x + 1, p.y + 1}}

                -- Act: a ghost for the robots to build
                local ghost = build(surface, 'entity-ghost', p, {inner_name = BUILDING})

                local function built()
                    return surface.count_entities_filtered {area = area, name = BUILDING}
                end

                -- Assert
                context:wait_until(1800, function()
                    return not ghost.valid and storage.get_item_count(BUILDING) == 1
                end, function()
                    return 'the ' .. BUILDING .. ' robots built on ore at ' .. p.x .. ',' .. p.y .. ' did not come back: ghost there ' .. tostring(ghost.valid) .. ', built ' .. built() .. ', in storage ' .. storage.get_item_count(BUILDING)
                end):next(function()
                    Assert.equal(0, built(), BUILDING .. 's left on ore')
                end)
            end
        )

        Declare.test(
            'a ghost of a building on ore is removed',
            function()
                -- Arrange
                local surface = RS.get_surface()
                local p = H.ore_spot(surface, BUILDING)
                Assert.is_true(p ~= nil, 'no ore near spawn to build on')
                local ghost = build(surface, 'entity-ghost', p, {inner_name = BUILDING})

                -- Act
                EventFactory.raise {name = defines.events.on_built_entity, tick = game.tick, player_index = 1, entity = ghost}

                -- Assert
                Assert.is_true(not ghost.valid, 'the ' .. BUILDING .. ' ghost on ore is still there')
            end
        )

        if prototypes.quality['rare'] then
            Declare.test(
                'a quality building on ore is handed back at its quality',
                function()
                    -- Arrange
                    local surface = RS.get_surface()
                    local p = H.ore_spot(surface, BUILDING)
                    Assert.is_true(p ~= nil, 'no ore near spawn to build on')
                    local chest = build(surface, BUILDING, p, {quality = 'rare'})

                    -- Act
                    local refunded = robot_builds(chest)

                    -- Assert
                    Assert.is_true(refunded ~= nil, 'nothing was handed back')
                    local quality = refunded.quality
                    Assert.equal('rare', type(quality) == 'string' and quality or quality.name, 'quality handed back')
                end
            )
        end
    end
)
