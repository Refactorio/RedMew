local Declare = require 'utils.test.declare'
local EventFactory = require 'utils.test.event_factory'
local Assert = require 'utils.test.assert'
local Helper = require 'utils.test.helper'

local main_inventory = defines.inventory.character_main
local config = global.config.landfill_remover

Declare.module(
    'landfill remover',
    function()
        local teardown

        Declare.module_startup(
            function(context)
                local player = game.get_player(1)
                teardown = Helper.startup_test_surface(context, player)
            end
        )

        Declare.module_teardown(
            function()
                teardown()
            end
        )

        Declare.test(
            'can remove landfill',
            function()
                -- Arrange
                local player = game.get_player(1)
                local surface = player.surface
                local position = {2, 2}

                surface.set_tiles({{name = 'landfill', position = position}})

                local inventory = player.get_inventory(main_inventory)
                inventory.clear()
                inventory.insert('deconstruction-planner')
                local stack = inventory.find_item_stack('deconstruction-planner')
                stack.set_tile_filter(1, 'landfill')

                local cursor = player.cursor_stack
                cursor.set_stack(stack)

                local area = {{2.1, 2.1}, {2.9, 2.9}}

                -- Act
                EventFactory.do_player_deconstruct_area(cursor, player, area)
                inventory.clear()

                -- Assert
                local tile = surface.get_tile(position[1], position[2])
                Assert.equal(config.revert_tile, tile.name)
            end
        )

        local items = {
            'stone-brick',
            'concrete',
            'hazard-concrete',
            'refined-concrete',
            'refined-hazard-concrete'
        }
        for _, item_name in pairs(items) do
            Declare.test(
                'can remove landfill when covered by ' .. item_name,
                function()
                    -- Arrange
                    local player = game.get_player(1)
                    local surface = player.surface
                    local position = {2, 2}
                    surface.set_tiles({{name = 'landfill', position = position}})

                    local cursor = player.cursor_stack
                    cursor.set_stack(item_name)
                    player.build_from_cursor({position = position, terrain_building_size = 1})

                    local inventory = player.get_inventory(main_inventory)
                    inventory.clear()

                    inventory.insert('deconstruction-planner')
                    local stack = inventory.find_item_stack('deconstruction-planner')
                    stack.set_tile_filter(1, 'landfill')

                    cursor.set_stack(stack)

                    local area = {{2.1, 2.1}, {2.9, 2.9}}

                    -- Act
                    EventFactory.do_player_deconstruct_area(cursor, player, area)
                    inventory.clear()

                    -- Assert
                    local tile = surface.get_tile(position[1], position[2])
                    Assert.equal(config.revert_tile, tile.name)
                end
            )
        end
    end
)
