-- In-game tests for concrete on landfill. These run on every Danger Ores map with it enabled
-- (the default): refined concrete laid on landfill becomes the marker tile, which can't be
-- mined, building another floor over the marker hands the refined concrete back, and mining
-- that floor and then the landfill gets back to the water the landfill was laid on. Landfill
-- with nothing under it stays that way, and refined concrete on ordinary ground stays refined
-- concrete.
--
-- Real construction robots lay and mine the tiles on a scratch surface, so the game does what
-- it does for a player: its own build checks, its own hidden tiles, its own events. The player
-- build path differs only in where the refund goes.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Helper = require 'utils.test.helper'
local DOC = require 'map_gen.maps.danger_ores.configuration'

local config = DOC.concrete_on_landfill
if not config.enabled then
    return
end

local MARKER = config.tile or 'blue-refined-concrete'
local REFUND = config.refund_tile or 'refined-concrete'
local STOCK = 10
local ROBOT_TICKS = 1800

Declare.module(
    {'map_gen', 'danger ores', 'concrete on landfill'},
    function()
        local surface, delete_surface
        local chest, remove_network

        Declare.module_startup(
            function(context)
                surface, delete_surface = Helper.create_test_surface(context)
                context:next(function()
                    chest, remove_network = Helper.robot_network(surface, {x = 0, y = 0}, {
                        {name = 'landfill', count = STOCK},
                        {name = REFUND, count = STOCK},
                        {name = 'stone-brick', count = STOCK}
                    })
                end)
            end
        )

        Declare.module_teardown(
            function()
                remove_network()
                delete_surface()
            end
        )

        local function layers(p)
            return surface.get_tile(p.x, p.y).name .. ' / ' .. tostring(surface.get_hidden_tile(p)) .. ' / ' .. tostring(surface.get_double_hidden_tile(p))
        end

        local function is_tile(p, name)
            return function()
                return surface.get_tile(p.x, p.y).name == name
            end
        end

        local function in_chest(name)
            return chest.get_inventory(defines.inventory.chest).get_item_count(name)
        end

        -- Does `act` the next tick, then waits for `done`; the test fails if it never comes, so each
        -- step asserts its own outcome.
        local function step(context, p, what, act, done)
            return context:next(act):wait_until(ROBOT_TICKS, done, function()
                return 'the robots did not ' .. what .. ' at ' .. p.x .. ',' .. p.y .. ': ' .. layers(p)
            end)
        end

        local function ghost(p, name)
            return function()
                local entity = surface.create_entity {name = 'tile-ghost', inner_name = name, position = p, force = 'player'}
                Assert.valid(entity, 'the ' .. name .. ' ghost was not placed at ' .. p.x .. ',' .. p.y)
            end
        end

        local function deconstruct(p)
            return function()
                local proxy = surface.get_tile(p.x, p.y).order_deconstruction('player')
                Assert.is_true(proxy ~= nil, 'the tile at ' .. p.x .. ',' .. p.y .. ' could not be marked for deconstruction: ' .. layers(p))
            end
        end

        Declare.test(
            'landfill under refined concrete can be dug back up to the water',
            function(context)
                -- Arrange
                local p = {x = 10, y = 0}
                surface.set_tiles {{name = 'water', position = p}}

                -- Act: landfill, then refined concrete on it
                step(context, p, 'lay landfill on the water', ghost(p, 'landfill'), is_tile(p, 'landfill'))
                step(context, p, 'lay refined concrete on the landfill', ghost(p, REFUND), is_tile(p, MARKER))

                -- Assert: it became the marker, which can't be mined
                context:next(function()
                    Assert.is_true(not prototypes.tile[MARKER].mineable_properties.minable, MARKER .. ' can be mined')
                    Assert.is_true(surface.get_tile(p.x, p.y).order_deconstruction('player') == nil, MARKER .. ' can be marked for deconstruction')
                end)

                -- Act and Assert: a floor over the marker hands the refined concrete back, and mining
                -- that floor and then the landfill gets back to the water
                local function path_and_refund()
                    return is_tile(p, 'stone-path')() and in_chest(REFUND) == STOCK
                end
                step(context, p, 'build stone path over the ' .. MARKER .. ' and hand the ' .. REFUND .. ' back', ghost(p, 'stone-path'), path_and_refund)
                step(context, p, 'mine the stone path down to landfill', deconstruct(p), is_tile(p, 'landfill'))
                step(context, p, 'mine the landfill down to water', deconstruct(p), is_tile(p, 'water'))
            end
        )

        Declare.test(
            'landfill with nothing under it ends up as it was, with nothing to mine',
            function(context)
                -- Arrange: landfill a map laid without anything under it can't be mined; refined
                -- concrete, a floor over that and mining the floor must not change that
                local p = {x = 10, y = 8}
                surface.set_tiles {{name = 'landfill', position = p}}
                surface.set_hidden_tile(p, nil)

                -- Act: refined concrete, stone path over it, then mine the stone path
                step(context, p, 'lay refined concrete on the landfill', ghost(p, REFUND), is_tile(p, MARKER))
                step(context, p, 'build stone path over the ' .. MARKER, ghost(p, 'stone-path'), is_tile(p, 'stone-path'))
                step(context, p, 'mine the stone path down to landfill', deconstruct(p), is_tile(p, 'landfill'))

                -- Assert
                context:next(function()
                    Assert.equal(nil, surface.get_hidden_tile(p), 'hidden tile under the landfill: ' .. layers(p))
                    Assert.is_true(surface.get_tile(p.x, p.y).order_deconstruction('player') == nil, 'the landfill can be mined: ' .. layers(p))
                end)
            end
        )

        Declare.test(
            'refined concrete on ordinary ground stays refined concrete',
            function(context)
                -- Arrange
                local p = {x = 14, y = 0}
                local function laid()
                    return surface.get_tile(p.x, p.y).name ~= 'grass-1'
                end

                -- Act
                step(context, p, 'lay refined concrete on the grass', ghost(p, REFUND), laid)

                -- Assert
                context:next(function()
                    Assert.equal(REFUND, surface.get_tile(p.x, p.y).name, 'tile after laying refined concrete on grass')
                end)
            end
        )
    end
)
