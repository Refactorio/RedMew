-- In-game tests for the shared entity placement restriction module. These run under _DEBUG
-- via /test-runner on any map that loads the module (danger ores, concrete jungle, dino
-- island, rail grid, the crash site presets).
--
-- The tests drive the banned and allowed lists rather than a keep_alive_callback, because
-- the callback is a single global slot owned by whichever map is loaded and there is no way
-- to read it back and restore it. Banned entities are destroyed before the callback is ever
-- consulted, and allowed entities return before it too, so these tests behave the same on
-- every map.
--
-- The main module raises the build events itself, on its own surface, so it runs without a
-- player (and so headless, in CI). Its refund checks read the item the module is about to
-- hand back from its pre-destroy event, because the refund itself goes to a player looked up
-- by index, which only exists in a real game. The 'player builds' module builds from a real
-- player's cursor and checks the item lands in their inventory; it needs a player.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Helper = require 'utils.test.helper'
local EventFactory = require 'utils.test.event_factory'
local Event = require 'utils.event'
local RestrictEntities = require 'map_gen.shared.entity_placement_restriction'

local BANNED = 'wooden-chest'
local ALLOWED = 'iron-chest'
local main_inventory = defines.inventory.character_main

-- what the module last said it was about to destroy (and refund)
local last_pre_destroy
Event.add(RestrictEntities.events.on_pre_restricted_entity_destroyed, function(event)
    last_pre_destroy = event
end)

-- Counts entities around a tile rather than at an exact position: an entity built from the
-- cursor snaps to the tile centre, so a position filter written as the tile coordinate
-- matches nothing and every "it was destroyed" assertion would pass for the wrong reason.
local function count_at(surface, name, position, is_ghost)
    local x, y = position[1], position[2]
    local filter = {area = {{x - 1, y - 1}, {x + 2, y + 2}}}
    if is_ghost then
        filter.ghost_name = name
    else
        filter.name = name
    end
    return surface.count_entities_filtered(filter)
end

-- Raises the player build event for an entity created from script, which doesn't raise it
-- itself. A real build event always has a player_index, and other features listening for it
-- rely on one, so it gets the test player's index, or on a headless run (no players) index 1,
-- which the module then finds no player for.
local function raise_player_build(context, entity)
    local player = context.player
    last_pre_destroy = nil
    EventFactory.raise {
        name = defines.events.on_built_entity,
        tick = game.tick,
        player_index = player and player.index or 1,
        entity = entity
    }
end

Declare.module(
    {'map_gen', 'entity placement restriction'},
    function()
        local surface, delete_surface
        local allowed_before

        -- Note: teardowns added to the startup context run as soon as startup finishes, so
        -- the lists have to be restored from module_teardown instead.
        Declare.module_startup(
            function(context)
                surface, delete_surface = Helper.create_test_surface(context)

                allowed_before = RestrictEntities.get_allowed()[ALLOWED]
                RestrictEntities.add_banned({BANNED})
                RestrictEntities.add_allowed({ALLOWED})
                -- The refund flag has no getter, so this is not restored on teardown. Every
                -- map that ships a rule today enables refunds anyway.
                RestrictEntities.enable_refund()
            end
        )

        Declare.module_teardown(
            function()
                RestrictEntities.remove_banned({BANNED})
                if not allowed_before then
                    RestrictEntities.remove_allowed({ALLOWED})
                end
                delete_surface()
            end
        )

        Declare.test(
            'a banned entity is destroyed and its item is handed back',
            function(context)
                -- Arrange
                local position = {4, 4}
                local entity = surface.create_entity {name = BANNED, position = position, force = 'player'}
                Assert.valid(entity, 'the test entity was not created')

                -- Act
                raise_player_build(context, entity)

                -- Assert
                Assert.equal(0, count_at(surface, BANNED, position), 'the banned entity survived')
                Assert.is_true(last_pre_destroy ~= nil, 'the module did not say it was destroying anything')
                Assert.equal(BANNED, last_pre_destroy.stack.name, 'the wrong item is handed back')
                Assert.equal(1, last_pre_destroy.stack.count, 'the wrong number of items is handed back')
            end
        )

        Declare.test(
            'an allowed entity is left alone',
            function(context)
                -- Arrange
                local position = {6, 6}
                local entity = surface.create_entity {name = ALLOWED, position = position, force = 'player'}
                Assert.valid(entity, 'the test entity was not created')
                context:add_teardown(function()
                    if entity.valid then
                        entity.destroy()
                    end
                end)

                -- Act
                raise_player_build(context, entity)

                -- Assert
                Assert.equal(1, count_at(surface, ALLOWED, position), 'an allowed entity was destroyed')
                Assert.is_true(last_pre_destroy == nil, 'the module set out to destroy an allowed entity')
            end
        )

        Declare.test(
            'a ghost of a banned entity is destroyed without a refund',
            function(context)
                -- Arrange: ghosts cost nothing to place, so refunding one would print items
                -- out of thin air.
                local position = {13, 13}
                local ghost = surface.create_entity {
                    name = 'entity-ghost',
                    inner_name = BANNED,
                    position = position,
                    force = 'player'
                }
                Assert.valid(ghost, 'the test ghost was not created')

                -- Act
                raise_player_build(context, ghost)

                -- Assert
                Assert.equal(0, count_at(surface, BANNED, position, true), 'the banned ghost survived')
                Assert.is_true(last_pre_destroy ~= nil, 'the module did not say it was destroying the ghost')
                Assert.is_true(last_pre_destroy.stack.name == nil, 'a ghost would be refunded ' .. tostring(last_pre_destroy.stack.name))
            end
        )

        Declare.test(
            'a banned entity built by a construction robot is destroyed and refunded to the robot',
            function(context)
                -- The rule used to hook player placement only, so any restriction could be
                -- sidestepped by placing a ghost and letting bots finish it.
                --
                -- A real bot build needs a roboport, power, a logistic network and a good
                -- many ticks of flying, so this raises the event the way Factorio would and
                -- checks the two things that were broken: that the rule runs for robot
                -- builds at all, and that the refund goes to the robot rather than nowhere. Real
                -- robots build it in the Safety Ores and allowed entities tests.

                -- Arrange
                local position = {17, 17}

                local robot = surface.create_entity {
                    name = 'construction-robot',
                    position = {17, 20},
                    force = 'player'
                }
                Assert.valid(robot, 'the test robot was not created')

                context:add_teardown(
                    function()
                        if robot.valid then
                            robot.destroy()
                        end
                    end
                )

                local entity = surface.create_entity {
                    name = BANNED,
                    position = position,
                    force = 'player'
                }
                Assert.valid(entity, 'the test entity was not created')

                -- The refund goes to the robot's cargo, as robot.insert takes nothing for a
                -- construction robot. The cargo is a stand-in that captures it; player_stats
                -- reads the network, to credit whoever owns the robot.
                local refunded
                local fake_robot =
                    Helper.fake_lua_object(
                    robot,
                    {
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
                    }
                )

                -- Act
                EventFactory.raise {
                    name = defines.events.on_robot_built_entity,
                    tick = game.tick,
                    robot = fake_robot,
                    entity = entity
                }

                -- Assert
                Assert.equal(0, count_at(surface, BANNED, position), 'a robot built entity ignored the rule')
                -- A plain table, not a LuaObject: Assert.valid would look for a valid field.
                Assert.is_true(refunded ~= nil, 'nothing was refunded to the robot')
                Assert.equal(BANNED, refunded.name, 'the wrong item was refunded to the robot')
            end
        )
    end
)

-- Building from a real player's cursor: these need a player, so they only run in game.
Declare.module(
    {'map_gen', 'entity placement restriction', 'player builds'},
    function()
        Declare.tags('skip-headless')

        local teardown

        Declare.module_startup(
            function(context)
                teardown = Helper.startup_test_surface(context)
            end
        )

        Declare.module_teardown(
            function()
                teardown()
            end
        )

        -- The item goes straight into the cursor and the main inventory is emptied after, so
        -- anything found in the inventory later can only have come from a refund. Going via
        -- the inventory instead would leave the original stack sitting there and make the
        -- count meaningless.
        local function give_to_cursor(player, item_name)
            player.cursor_stack.set_stack({name = item_name, count = 1})
            player.get_inventory(main_inventory).clear()
        end

        -- build_from_cursor silently does nothing when the position is out of reach, which
        -- would otherwise look exactly like "the rule destroyed it".
        local function build(player, position)
            Assert.is_true(player.can_build_from_cursor({position = position}),
                'the test cannot build at this position')
            player.build_from_cursor({position = position})
        end

        Declare.test(
            'a banned entity built by a player is destroyed and the item refunded',
            function(context)
                -- Arrange: the item lives in the cursor, so the main inventory starts empty
                -- and anything found there afterwards can only be the refund.
                local player = context.player
                local surface = player.surface
                local position = {4, 4}
                give_to_cursor(player, BANNED)

                -- Act
                build(player, position)

                -- Assert
                Assert.equal(0, count_at(surface, BANNED, position), 'the banned entity survived')
                Assert.is_true(not player.cursor_stack.valid_for_read, 'the build did not consume the item')
                Assert.equal(1, player.get_inventory(main_inventory).get_item_count(BANNED),
                    'the item was not refunded')
            end
        )

        Declare.test(
            'an allowed entity built by a player is left alone',
            function(context)
                -- Arrange
                local player = context.player
                local surface = player.surface
                local position = {6, 6}
                give_to_cursor(player, ALLOWED)

                context:add_teardown(
                    function()
                        local entity = surface.find_entity(ALLOWED, position)
                        if entity and entity.valid then
                            entity.destroy()
                        end
                    end
                )

                -- Act
                build(player, position)

                -- Assert
                Assert.equal(1, count_at(surface, ALLOWED, position), 'an allowed entity was destroyed')
                Assert.equal(0, player.get_inventory(main_inventory).get_item_count(ALLOWED),
                    'an allowed entity should not be refunded')
            end
        )
    end
)
