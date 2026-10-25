-- In-game tests for the ore mined score. These run on every Danger Ores map with it enabled
-- (the default): ore produced on the map counts towards it, at every quality, and other items
-- don't.
--
-- They add to the player force's production statistics directly, the way mining does. Since
-- Factorio 2.1 a flow shows up in the statistics a little later, so each test waits for its own.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local OreMined = require 'map_gen.maps.danger_ores.modules.ore_mined'
local RS = require 'map_gen.shared.redmew_surface'

if not DOC.ore_mined.enabled then
    return
end

local WAIT_TICKS = 120 -- how long a flow may take to show up in the statistics

Declare.module(
    {'map_gen', 'danger ores', 'ore mined'},
    function()
        local function stats()
            return game.forces.player.get_item_production_statistics(RS.get_surface_name())
        end

        local function produced(item)
            return stats().get_input_count(item)
        end

        Declare.test(
            'ore produced on the map counts as mined',
            function(context)
                -- Arrange
                local counts, total = OreMined.get_ore_mined()
                local coal = counts['coal']
                Assert.is_true(coal ~= nil, 'coal is not counted as ore')
                local before = produced('coal')

                -- Act
                stats().on_flow('coal', 100)

                -- Assert
                context:wait_until(WAIT_TICKS, function()
                    return produced('coal') == before + 100
                end, 'the 100 coal never showed up in the statistics'):next(function()
                    local after, after_total = OreMined.get_ore_mined()
                    Assert.equal(coal + 100, after['coal'], 'coal mined after producing 100')
                    Assert.equal(total + 100, after_total, 'ore mined after producing 100 coal')
                end)
            end
        )

        Declare.test(
            'other items do not count',
            function(context)
                -- Arrange
                local _, total = OreMined.get_ore_mined()
                local before = produced('iron-plate')

                -- Act
                stats().on_flow('iron-plate', 100)

                -- Assert
                context:wait_until(WAIT_TICKS, function()
                    return produced('iron-plate') == before + 100
                end, 'the 100 iron plates never showed up in the statistics'):next(function()
                    local _, after = OreMined.get_ore_mined()
                    Assert.equal(total, after, 'ore mined after producing 100 iron plates')
                end)
            end
        )

        if prototypes.quality['rare'] then
            Declare.test(
                'quality ore counts too',
                function(context)
                    -- Arrange
                    local _, total = OreMined.get_ore_mined()
                    local rare_stone = {name = 'stone', quality = 'rare'}
                    local before = produced(rare_stone)

                    -- Act
                    stats().on_flow(rare_stone, 10)

                    -- Assert
                    context:wait_until(WAIT_TICKS, function()
                        return produced(rare_stone) == before + 10
                    end, 'the 10 rare stone never showed up in the statistics'):next(function()
                        local _, after = OreMined.get_ore_mined()
                        Assert.equal(total + 10, after, 'ore mined after producing 10 rare stone')
                    end)
                end
            )
        end
    end
)
