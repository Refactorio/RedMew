-- In-game tests for expanse. These run on maps that use it (DO/Expanse): the land beyond the
-- starting area is void, hungry chests sit on its edge, and feeding one what it asks for opens
-- the land behind it, with new chests on the far side. The Elder Tree and the Infinity Rock at
-- spawn grow back when mined.
--
-- The chests are fed by inserting their request straight into them, as bots would. Mining
-- needs a player, so the infinite resources are tested by raising the pre-mined event the way
-- Factorio does just before the entity goes.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local EventFactory = require 'utils.test.event_factory'
local LP = require 'utils.logistic_point'
local H = require 'map_gen.maps.danger_ores.modules.terrain_test_helper'

local CELL = 32
local CELL_TILES = CELL * CELL
local RADIUS = 3 -- how far from a chest its void is looked for, as in expanse.lua
local DIRECTIONS = {{-RADIUS, 0}, {RADIUS, 0}, {0, RADIUS}, {0, -RADIUS}}

-- The map, generated out to a cell past the starting area (256 tiles across on DO/Expanse).
local function surface_around_start()
    return H.generate_around(0, 0, 128 + CELL)
end

local function void_count(surface, left_top)
    return surface.count_tiles_filtered {area = {left_top, {left_top.x + CELL, left_top.y + CELL}}, name = 'out-of-map'}
end

local function cell_of(position)
    local x, y = math.floor(position.x), math.floor(position.y)
    return {x = x - x % CELL, y = y - y % CELL}
end

local function hungry_chests(surface, area)
    return surface.find_entities_filtered {name = 'requester-chest', force = 'neutral', area = area}
end

-- The void cells next to a chest: the ones it opens when fed.
local function void_cells_by(surface, chest)
    local cells = {}
    for _, v in pairs(DIRECTIONS) do
        local position = {x = chest.position.x + v[1], y = chest.position.y + v[2]}
        if surface.get_tile(position.x, position.y).name == 'out-of-map' then
            cells[#cells + 1] = cell_of(position)
        end
    end
    return cells
end

Declare.module(
    {'map_gen', 'danger ores', 'expanse'},
    function()
        Declare.test(
            'the land beyond the starting area is void',
            function()
                -- Act
                local surface = surface_around_start()

                -- Assert
                Assert.is_true(surface.get_tile(0, 0).name ~= 'out-of-map', 'spawn is void')
                local edge
                for x = 0, 1024 do
                    if surface.get_tile(x, 0).name == 'out-of-map' then
                        edge = x
                        break
                    end
                end
                Assert.is_true(edge ~= nil, 'no void east of spawn')
                Assert.equal(0, edge % CELL, 'the starting area ends at ' .. edge .. ', not on a cell edge')
                Assert.equal(CELL_TILES, void_count(surface, {x = edge, y = 0}), 'void tiles in the cell past the starting area')
            end
        )

        Declare.test(
            'hungry chests sit on the edge of the starting area',
            function()
                -- Act
                local surface = surface_around_start()

                -- Assert
                local chests = hungry_chests(surface)
                Assert.is_true(#chests >= 4, 'only ' .. #chests .. ' hungry chests')
                for _, chest in pairs(chests) do
                    local where = chest.position.x .. ',' .. chest.position.y
                    Assert.is_true(#void_cells_by(surface, chest) > 0, 'the hungry chest at ' .. where .. ' is not next to the void')
                    Assert.is_true(not chest.minable and not chest.destructible, 'the hungry chest at ' .. where .. ' can be removed')
                    Assert.is_true(#LP.get_filters(chest.get_logistic_point(defines.logistic_member_index.logistic_container)) > 0,
                        'the hungry chest at ' .. where .. ' asks for nothing')
                end
            end
        )

        Declare.test(
            'feeding a hungry chest opens the land behind it',
            function(context)
                -- Arrange
                local surface = surface_around_start()
                local chest = hungry_chests(surface)[1]
                Assert.valid(chest, 'no hungry chest')
                local where = chest.position.x .. ',' .. chest.position.y
                local cells = void_cells_by(surface, chest)

                -- Act: everything it asks for
                for _, filter in pairs(LP.get_filters(chest.get_logistic_point(defines.logistic_member_index.logistic_container))) do
                    chest.insert {name = filter.value.name, quality = filter.value.quality, count = filter.min}
                end

                -- Assert: expanse looks at one chest per tick; poll until it has got round to this one
                local tries = 20
                local function check()
                    local opened
                    for _, cell in pairs(cells) do
                        if void_count(surface, cell) < CELL_TILES then
                            opened = cell
                        end
                    end
                    if not opened then
                        tries = tries - 1
                        Assert.is_true(tries > 0, 'the land behind the hungry chest at ' .. where .. ' did not open')
                        context:timeout(30, check)
                        return
                    end
                    Assert.is_true(not chest.valid, 'the fed hungry chest at ' .. where .. ' is still there')
                    local new = hungry_chests(surface, {{opened.x, opened.y}, {opened.x + CELL, opened.y + CELL}})
                    Assert.is_true(#new > 0, 'no hungry chests on the land opened at ' .. opened.x .. ',' .. opened.y)
                end
                context:timeout(30, check)
            end
        )

        Declare.test(
            'the Infinity Rock grows back when mined and drops ore',
            function()
                -- Arrange
                local surface = surface_around_start()
                local rock = surface.find_entities_filtered {name = 'huge-rock', position = {0, 8}, radius = 1}[1]
                Assert.valid(rock, 'no Infinity Rock at spawn')
                local items = surface.count_entities_filtered {name = 'item-on-ground', position = rock.position, radius = 5}

                -- Act: mine it the way a player does
                EventFactory.raise {name = defines.events.on_pre_player_mined_item, tick = game.tick, player_index = 1, entity = rock}
                rock.destroy()

                -- Assert
                local again = surface.find_entities_filtered {name = 'huge-rock', position = {0, 8}, radius = 1}[1]
                Assert.valid(again, 'the Infinity Rock did not grow back')
                Assert.is_true(not again.destructible, 'the Infinity Rock can be destroyed')
                Assert.is_true(surface.count_entities_filtered {name = 'item-on-ground', position = again.position, radius = 5} > items, 'mining the Infinity Rock dropped nothing')
            end
        )

        Declare.test(
            'the Elder Tree grows back when mined',
            function()
                -- Arrange
                local surface = surface_around_start()
                local tree = surface.find_entities_filtered {type = 'tree', position = {0, -8}, radius = 1}[1]
                Assert.valid(tree, 'no Elder Tree at spawn')

                -- Act: mine it the way a player does
                EventFactory.raise {name = defines.events.on_pre_player_mined_item, tick = game.tick, player_index = 1, entity = tree}
                tree.destroy()

                -- Assert
                local again = surface.find_entities_filtered {type = 'tree', position = {0, -8}, radius = 1}[1]
                Assert.valid(again, 'the Elder Tree did not grow back')
                Assert.is_true(not again.destructible, 'the Elder Tree can be destroyed')
            end
        )
    end
)
