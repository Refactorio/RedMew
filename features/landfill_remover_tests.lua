local Declare = require 'utils.test.declare'
local EventFactory = require 'utils.test.event_factory'
local Assert = require 'utils.test.assert'
local Helper = require 'utils.test.helper'
local Rank = require 'features.rank_system'
local Ranks = require 'resources.ranks'
local LandfillRemover = require 'features.landfill_remover'

local main_inventory = defines.inventory.character_main
local config = storage.config.landfill_remover

local tile_items = {
    'stone-brick',
    'concrete',
    'hazard-concrete',
    'refined-concrete',
    'refined-hazard-concrete'
}

Declare.module(
    {'features', 'landfill remover'},
    function()
        local teardown
        local old_landfill_researched

        Declare.module_startup(
            function(context)
                teardown = Helper.startup_test_surface(context)
                old_landfill_researched = context.player.force.technologies['landfill'].researched
                context.player.force.technologies['landfill'].researched = true
            end
        )

        Declare.module_teardown(
            function(context)
                teardown()
                context.player.force.technologies['landfill'].researched = old_landfill_researched
            end
        )

        local function setup_player_with_default_deconstruction_planner(player)
            local inventory = player.get_inventory(main_inventory)
            inventory.clear()
            inventory.insert('deconstruction-planner')
            local stack = inventory.find_item_stack('deconstruction-planner')

            local cursor = player.cursor_stack
            cursor.set_stack(stack)

            return cursor
        end

        local function setup_player_with_valid_deconstruction_planner(player)
            local inventory = player.get_inventory(main_inventory)
            inventory.clear()
            inventory.insert('deconstruction-planner')
            local stack = inventory.find_item_stack('deconstruction-planner')
            stack.set_tile_filter(1, 'landfill')
            stack.tile_selection_mode = defines.deconstruction_item.tile_selection_mode.only

            local cursor = player.cursor_stack
            cursor.set_stack(stack)

            return cursor
        end

        local function setup_player_with_tile_filter_whitelist_deconstruction_planner(player)
            local inventory = player.get_inventory(main_inventory)
            inventory.clear()
            inventory.insert('deconstruction-planner')
            local stack = inventory.find_item_stack('deconstruction-planner')
            stack.set_tile_filter(1, 'landfill')
            stack.tile_filter_mode = defines.deconstruction_item.tile_filter_mode.whitelist

            local cursor = player.cursor_stack
            cursor.set_stack(stack)

            return cursor
        end

        local function setup_player_with_tile_filter_blacklist_deconstruction_planner(player)
            local inventory = player.get_inventory(main_inventory)
            inventory.clear()
            inventory.insert('deconstruction-planner')
            local stack = inventory.find_item_stack('deconstruction-planner')
            stack.set_tile_filter(1, 'landfill')
            stack.tile_filter_mode = defines.deconstruction_item.tile_filter_mode.blacklist

            local cursor = player.cursor_stack
            cursor.set_stack(stack)

            return cursor
        end

        local function setup_player_with_normal_selection_mode_deconstruction_planner(player)
            local inventory = player.get_inventory(main_inventory)
            inventory.clear()
            inventory.insert('deconstruction-planner')
            local stack = inventory.find_item_stack('deconstruction-planner')
            stack.set_tile_filter(1, 'landfill')
            stack.tile_selection_mode = defines.deconstruction_item.tile_selection_mode.normal

            local cursor = player.cursor_stack
            cursor.set_stack(stack)

            return cursor
        end

        local function setup_player_with_never_selection_mode_deconstruction_planner(player)
            local inventory = player.get_inventory(main_inventory)
            inventory.clear()
            inventory.insert('deconstruction-planner')
            local stack = inventory.find_item_stack('deconstruction-planner')
            stack.set_tile_filter(1, 'landfill')
            stack.tile_selection_mode = defines.deconstruction_item.tile_selection_mode.never

            local cursor = player.cursor_stack
            cursor.set_stack(stack)

            return cursor
        end

        local function setup_player_with_always_selection_mode_deconstruction_planner(player)
            local inventory = player.get_inventory(main_inventory)
            inventory.clear()
            inventory.insert('deconstruction-planner')
            local stack = inventory.find_item_stack('deconstruction-planner')
            stack.set_tile_filter(1, 'landfill')
            stack.tile_selection_mode = defines.deconstruction_item.tile_selection_mode.always

            local cursor = player.cursor_stack
            cursor.set_stack(stack)

            return cursor
        end

        local function setup_player_with_no_landfill_deconstruction_planner(player)
            local inventory = player.get_inventory(main_inventory)
            inventory.clear()
            inventory.insert('deconstruction-planner')
            local stack = inventory.find_item_stack('deconstruction-planner')
            stack.tile_selection_mode = defines.deconstruction_item.tile_selection_mode.only

            local cursor = player.cursor_stack
            cursor.set_stack(stack)

            return cursor
        end

        local function setup_player_with_trees_and_rocks_only_deconstruction_planner(player)
            local inventory = player.get_inventory(main_inventory)
            inventory.clear()
            inventory.insert('deconstruction-planner')
            local stack = inventory.find_item_stack('deconstruction-planner')
            stack.set_tile_filter(1, 'landfill')
            stack.trees_and_rocks_only = true

            local cursor = player.cursor_stack
            cursor.set_stack(stack)

            return cursor
        end

        local function setup_player_with_entity_filter_whitelist_deconstruction_planner(player)
            local inventory = player.get_inventory(main_inventory)
            inventory.clear()
            inventory.insert('deconstruction-planner')
            local stack = inventory.find_item_stack('deconstruction-planner')
            stack.set_tile_filter(1, 'landfill')
            stack.set_entity_filter(1, 'iron-chest')
            stack.entity_filter_mode = defines.deconstruction_item.entity_filter_mode.whitelist

            local cursor = player.cursor_stack
            cursor.set_stack(stack)

            return cursor
        end

        local function setup_player_with_entity_filter_blacklist_deconstruction_planner(player)
            local inventory = player.get_inventory(main_inventory)
            inventory.clear()
            inventory.insert('deconstruction-planner')
            local stack = inventory.find_item_stack('deconstruction-planner')
            stack.set_tile_filter(1, 'landfill')
            stack.set_entity_filter(1, 'iron-chest')
            stack.entity_filter_mode = defines.deconstruction_item.entity_filter_mode.blacklist

            local cursor = player.cursor_stack
            cursor.set_stack(stack)

            return cursor
        end

        Declare.test(
            'can remove landfill',
            function(context)
                -- Arrange
                local player = context.player
                local surface = player.surface
                local cursor = setup_player_with_valid_deconstruction_planner(player)
                local position = {2, 2}
                local area = {{2.1, 2.1}, {2.9, 2.9}}
                surface.set_tiles({{name = 'landfill', position = position}})

                -- Act
                EventFactory.do_player_deconstruct_area(cursor, player, area)

                -- Assert
                local tile = surface.get_tile(position[1], position[2])
                Assert.equal(config.revert_tile, tile.name)
            end
        )

        for _, item_name in pairs(tile_items) do
            Declare.test(
                'can remove landfill when covered by ' .. item_name,
                function(context)
                    -- Arrange
                    local player = context.player
                    local surface = player.surface
                    local position = {2, 2}
                    local area = {{2.1, 2.1}, {2.9, 2.9}}
                    surface.set_tiles({{name = 'landfill', position = position}})

                    -- Place covering tile.
                    local cursor = player.cursor_stack
                    cursor.set_stack(item_name)
                    player.build_from_cursor({position = position, terrain_building_size = 1})

                    cursor = setup_player_with_valid_deconstruction_planner(player)

                    -- Act
                    EventFactory.do_player_deconstruct_area(cursor, player, area)

                    -- Assert
                    local tile = surface.get_tile(position[1], position[2])
                    Assert.equal(config.revert_tile, tile.name)
                end
            )
        end

        Declare.test(
            'does not remove landfill when entity present',
            function(context)
                -- Arrange
                local player = context.player
                local surface = player.surface
                local position = {2, 2}
                local area = {{2.1, 2.1}, {2.9, 2.9}}
                surface.set_tiles({{name = 'landfill', position = position}})

                -- Place entity.
                local cursor = player.cursor_stack
                cursor.set_stack('iron-chest')
                player.build_from_cursor({position = position})

                cursor = setup_player_with_valid_deconstruction_planner(player)

                -- Act
                EventFactory.do_player_deconstruct_area(cursor, player, area)

                -- Assert
                local tile = surface.get_tile(position[1], position[2])
                Assert.equal('landfill', tile.name)

                local entities = surface.find_entities(area)
                local entity = entities[1]
                Assert.is_lua_object_with_name(entity, 'iron-chest', 'iron-chest was not valid.')
                entity.destroy()
            end
        )

        for _, item_name in pairs(tile_items) do
            Declare.test(
                'does not remove covered by ' .. item_name .. ' landfill when entity present',
                function(context)
                    -- Arrange
                    local player = context.player
                    local surface = player.surface
                    local position = {2, 2}
                    local area = {{2.1, 2.1}, {2.9, 2.9}}
                    surface.set_tiles({{name = 'landfill', position = position}})

                    -- Place covering tile.
                    local cursor = player.cursor_stack
                    cursor.set_stack(item_name)
                    player.build_from_cursor({position = position, terrain_building_size = 1})

                    local before_tile = surface.get_tile(position[1], position[2])

                    -- Place entity.
                    cursor.set_stack('iron-chest')
                    player.build_from_cursor({position = position})

                    cursor = setup_player_with_valid_deconstruction_planner(player)

                    -- Act
                    EventFactory.do_player_deconstruct_area(cursor, player, area)

                    -- Assert
                    local tile = surface.get_tile(position[1], position[2])
                    Assert.equal(before_tile.name, tile.name)

                    local entities = surface.find_entities(area)
                    local entity = entities[1]
                    Assert.is_lua_object_with_name(entity, 'iron-chest', 'iron-chest was not valid.')
                    entity.destroy()
                end
            )
        end

        Declare.test(
            'does not remove landfill when out of reach',
            function(context)
                -- Arrange
                local player = context.player
                local surface = player.surface
                local build_distance = player.build_distance + 5
                local position = {build_distance, build_distance}
                local area = {
                    {build_distance + 0.1, build_distance + 0.1},
                    {build_distance + 0.9, build_distance + 0.9}
                }
                surface.set_tiles({{name = 'landfill', position = position}})
                local cursor = setup_player_with_valid_deconstruction_planner(player)

                -- Act
                EventFactory.do_player_deconstruct_area(cursor, player, area)

                -- Assert
                local tile = surface.get_tile(position[1], position[2])
                Assert.equal('landfill', tile.name)
            end
        )

        for _, item_name in pairs(tile_items) do
            Declare.test(
                'does not remove landfill when out of reach and covered by ' .. item_name,
                function(context)
                    -- Arrange
                    local player = context.player
                    local surface = player.surface
                    local build_distance = player.build_distance + 5
                    local position = {build_distance, build_distance}
                    local area = {
                        {build_distance + 0.1, build_distance + 0.1},
                        {build_distance + 0.9, build_distance + 0.9}
                    }
                    surface.set_tiles({{name = 'landfill', position = position}})

                    -- Place covering tile.
                    local cursor = player.cursor_stack
                    cursor.set_stack(item_name)
                    player.build_from_cursor({position = position, terrain_building_size = 1})

                    local before_tile = surface.get_tile(position[1], position[2])

                    cursor = setup_player_with_valid_deconstruction_planner(player)

                    -- Act
                    EventFactory.do_player_deconstruct_area(cursor, player, area)

                    -- Assert
                    local tile = surface.get_tile(position[1], position[2])
                    Assert.equal(before_tile.name, tile.name)
                end
            )
        end

        Declare.test(
            'does not remove landfill when trees and rocks only',
            function(context)
                -- Arrange
                local player = context.player
                local surface = player.surface
                local position = {2, 2}
                local area = {{2.1, 2.1}, {2.9, 2.9}}
                surface.set_tiles({{name = 'landfill', position = position}})
                local cursor = setup_player_with_trees_and_rocks_only_deconstruction_planner(player)

                -- Act
                EventFactory.do_player_deconstruct_area(cursor, player, area)

                -- Assert
                local tile = surface.get_tile(position[1], position[2])
                Assert.equal('landfill', tile.name)
            end
        )

        Declare.test(
            'does not remove landfill when default deconstruction planner',
            function(context)
                -- Arrange
                local player = context.player
                local surface = player.surface
                local position = {2, 2}
                local area = {{2.1, 2.1}, {2.9, 2.9}}
                surface.set_tiles({{name = 'landfill', position = position}})
                local cursor = setup_player_with_default_deconstruction_planner(player)

                -- Act
                EventFactory.do_player_deconstruct_area(cursor, player, area)

                -- Assert
                local tile = surface.get_tile(position[1], position[2])
                Assert.equal('landfill', tile.name)
            end
        )

        local tile_mode_test_cases = {
            {
                name = 'only',
                setup = setup_player_with_valid_deconstruction_planner,
                should_remove = true
            },
            {
                name = 'normal',
                setup = setup_player_with_normal_selection_mode_deconstruction_planner,
                should_remove = true
            },
            {
                name = 'always',
                setup = setup_player_with_always_selection_mode_deconstruction_planner,
                should_remove = true
            },
            {
                name = 'never',
                setup = setup_player_with_never_selection_mode_deconstruction_planner,
                should_remove = false
            },
            {
                name = 'no landfill',
                setup = setup_player_with_no_landfill_deconstruction_planner,
                should_remove = false
            }
        }

        for _, test_case in pairs(tile_mode_test_cases) do
            Declare.test(
                'tile mode ' ..
                    test_case.name .. ' should ' .. (test_case.should_remove and '' or 'not ') .. 'remove landfill',
                function(context)
                    -- Arrange
                    local player = context.player
                    local surface = player.surface
                    local cursor = test_case.setup(player)
                    local position = {2, 2}
                    local area = {{2.1, 2.1}, {2.9, 2.9}}
                    surface.set_tiles({{name = 'landfill', position = position}})
                    local expected_tile = test_case.should_remove and config.revert_tile or 'landfill'

                    -- Act
                    EventFactory.do_player_deconstruct_area(cursor, player, area)

                    -- Assert
                    local tile = surface.get_tile(position[1], position[2])
                    Assert.equal(expected_tile, tile.name)
                end
            )
        end

        local tile_filter_test_cases = {
            {
                name = 'whitelist',
                setup = setup_player_with_tile_filter_whitelist_deconstruction_planner,
                should_remove = true
            },
            {
                name = 'blacklist',
                setup = setup_player_with_tile_filter_blacklist_deconstruction_planner,
                should_remove = false
            }
        }

        for _, test_case in pairs(tile_filter_test_cases) do
            Declare.test(
                'tile filter ' ..
                    test_case.name .. ' should ' .. (test_case.should_remove and '' or 'not ') .. 'remove landfill',
                function(context)
                    -- Arrange
                    local player = context.player
                    local surface = player.surface
                    local cursor = test_case.setup(player)
                    local position = {2, 2}
                    local area = {{2.1, 2.1}, {2.9, 2.9}}
                    surface.set_tiles({{name = 'landfill', position = position}})
                    local expected_tile = test_case.should_remove and config.revert_tile or 'landfill'

                    -- Act
                    EventFactory.do_player_deconstruct_area(cursor, player, area)

                    -- Assert
                    local tile = surface.get_tile(position[1], position[2])
                    Assert.equal(expected_tile, tile.name)
                end
            )
        end

        local tile_mode_with_entity_test_cases = {
            {
                name = 'only',
                setup = setup_player_with_valid_deconstruction_planner,
                should_remove = true
            },
            {
                name = 'normal',
                setup = setup_player_with_normal_selection_mode_deconstruction_planner,
                should_remove = false
            },
            {
                name = 'always',
                setup = setup_player_with_always_selection_mode_deconstruction_planner,
                should_remove = true
            },
            {
                name = 'never',
                setup = setup_player_with_never_selection_mode_deconstruction_planner,
                should_remove = false
            },
            {
                name = 'no landfill',
                setup = setup_player_with_no_landfill_deconstruction_planner,
                should_remove = false
            }
        }

        for _, test_case in pairs(tile_mode_with_entity_test_cases) do
            Declare.test(
                'tile mode ' ..
                    test_case.name ..
                        ' with entity should ' .. (test_case.should_remove and '' or 'not ') .. 'remove landfill',
                function(context)
                    -- Arrange
                    local player = context.player
                    local surface = player.surface

                    local position1 = {2, 2}
                    local position2 = {3, 2}
                    local area = {{2.1, 2.1}, {3.9, 2.9}}
                    surface.set_tiles(
                        {{name = 'landfill', position = position1}, {name = 'landfill', position = position2}}
                    )
                    local expected_tile = test_case.should_remove and config.revert_tile or 'landfill'

                    -- Place entity.
                    local cursor = player.cursor_stack
                    cursor.set_stack('iron-chest')
                    player.build_from_cursor({position = position1})

                    cursor = test_case.setup(player)

                    -- Act
                    EventFactory.do_player_deconstruct_area(cursor, player, area)

                    -- Assert
                    local tile = surface.get_tile(position2[1], position2[2])
                    Assert.equal(expected_tile, tile.name)

                    local entities = surface.find_entities(area)
                    local entity = entities[1]
                    Assert.is_lua_object_with_name(entity, 'iron-chest', 'iron-chest was not valid.')
                    entity.destroy()
                end
            )
        end

        local tile_filter_with_entity_test_cases = {
            {
                name = 'whitelist',
                setup = setup_player_with_tile_filter_whitelist_deconstruction_planner,
                should_remove = false
            },
            {
                name = 'blacklist',
                setup = setup_player_with_tile_filter_blacklist_deconstruction_planner,
                should_remove = false
            }
        }

        for _, test_case in pairs(tile_filter_with_entity_test_cases) do
            Declare.test(
                'tile mode ' ..
                    test_case.name ..
                        ' with entity should ' .. (test_case.should_remove and '' or 'not ') .. 'remove landfill',
                function(context)
                    -- Arrange
                    local player = context.player
                    local surface = player.surface

                    local position1 = {2, 2}
                    local position2 = {3, 2}
                    local area = {{2.1, 2.1}, {3.9, 2.9}}
                    surface.set_tiles(
                        {{name = 'landfill', position = position1}, {name = 'landfill', position = position2}}
                    )
                    local expected_tile = test_case.should_remove and config.revert_tile or 'landfill'

                    -- Place entity.
                    local cursor = player.cursor_stack
                    cursor.set_stack('iron-chest')
                    player.build_from_cursor({position = position1})

                    cursor = test_case.setup(player)

                    -- Act
                    EventFactory.do_player_deconstruct_area(cursor, player, area)

                    -- Assert
                    local tile = surface.get_tile(position2[1], position2[2])
                    Assert.equal(expected_tile, tile.name)

                    local entities = surface.find_entities(area)
                    local entity = entities[1]
                    Assert.is_lua_object_with_name(entity, 'iron-chest', 'iron-chest was not valid.')
                    entity.destroy()
                end
            )
        end

        local entity_filter_with_entity_test_cases = {
            {
                name = 'whitelist',
                setup = setup_player_with_entity_filter_whitelist_deconstruction_planner,
                should_remove = false
            },
            {
                name = 'blacklist',
                setup = setup_player_with_entity_filter_blacklist_deconstruction_planner,
                should_remove = true
            }
        }

        for _, test_case in pairs(entity_filter_with_entity_test_cases) do
            Declare.test(
                'entity filter ' ..
                    test_case.name ..
                        ' with entity should ' .. (test_case.should_remove and '' or 'not ') .. 'remove landfill',
                function(context)
                    -- Arrange
                    local player = context.player
                    local surface = player.surface

                    local position1 = {2, 2}
                    local position2 = {3, 2}
                    local area = {{2.1, 2.1}, {3.9, 2.9}}
                    surface.set_tiles(
                        {{name = 'landfill', position = position1}, {name = 'landfill', position = position2}}
                    )
                    local expected_tile = test_case.should_remove and config.revert_tile or 'landfill'

                    -- Place entity.
                    local cursor = player.cursor_stack
                    cursor.set_stack('iron-chest')
                    player.build_from_cursor({position = position1})

                    cursor = test_case.setup(player)

                    -- Act
                    EventFactory.do_player_deconstruct_area(cursor, player, area)

                    -- Assert
                    local tile = surface.get_tile(position2[1], position2[2])
                    Assert.equal(expected_tile, tile.name)

                    local entities = surface.find_entities(area)
                    local entity = entities[1]
                    Assert.is_lua_object_with_name(entity, 'iron-chest', 'iron-chest was not valid.')
                    entity.destroy()
                end
            )
        end

        Declare.test(
            'ignore character when removing landfill',
            function(context)
                -- Arrange
                local player = context.player
                local surface = player.surface
                local cursor = setup_player_with_valid_deconstruction_planner(player)
                local positions = {
                    {-1, -1},
                    {-1, 0},
                    {0, -1},
                    {0, 0}
                }
                local area = {{-1.5, -1.5}, {0.5, 0.5}}

                surface.set_tiles(
                    {
                        {name = 'landfill', position = positions[1]},
                        {name = 'landfill', position = positions[2]},
                        {name = 'landfill', position = positions[3]},
                        {name = 'landfill', position = positions[4]}
                    }
                )

                -- Act
                EventFactory.do_player_deconstruct_area(cursor, player, area)

                -- Assert
                for _, pos in pairs(positions) do
                    local tile = surface.get_tile(pos[1], pos[2])
                    Assert.equal(config.revert_tile, tile.name)
                end
            end
        )

        Declare.test(
            'can not remove landfill when guest',
            function(context)
                -- Arrange
                local player = context.player
                local surface = player.surface
                local cursor = setup_player_with_valid_deconstruction_planner(player)
                local position = {2, 2}
                local area = {{2.1, 2.1}, {2.9, 2.9}}
                surface.set_tiles({{name = 'landfill', position = position}})

                player.admin = false
                local old_rank = Rank.get_player_rank(player.name)
                Rank.set_player_rank(player.name, Ranks.guest)

                context:add_teardown(function()
                    player.admin = true
                    Rank.set_player_rank(player.name, old_rank)
                end)

                local messages = {}

                Helper.modify_lua_object(context, player, 'print', function(text)
                    messages[#messages+1] = text
                end)

                Helper.modify_lua_object(context, game, 'get_player', function()
                    return player
                end)

                -- Act
                EventFactory.do_player_deconstruct_area(cursor, player, area)

                -- Assert
                local tile = surface.get_tile(position[1], position[2])
                Assert.equal('landfill', tile.name)

                Assert.array_contains(messages, LandfillRemover.rank_too_low_message)
            end
        )

        Declare.test(
            'can not remove landfill when landfill tech not researched',
            function(context)
                -- Arrange
                local player = context.player
                local surface = player.surface
                local cursor = setup_player_with_valid_deconstruction_planner(player)
                local position = {2, 2}
                local area = {{2.1, 2.1}, {2.9, 2.9}}
                surface.set_tiles({{name = 'landfill', position = position}})

                player.force.technologies['landfill'].researched = false

                context:add_teardown(function()
                    player.force.technologies['landfill'].researched = true
                end)

                local messages = {}

                Helper.modify_lua_object(context, player, 'print', function(text)
                    messages[#messages+1] = text
                end)

                Helper.modify_lua_object(context, game, 'get_player', function()
                    return player
                end)

                -- Act
                EventFactory.do_player_deconstruct_area(cursor, player, area)

                -- Assert
                local tile = surface.get_tile(position[1], position[2])
                Assert.equal('landfill', tile.name)

                Assert.array_contains(messages, LandfillRemover.missing_research_message)
            end
        )
    end
)
