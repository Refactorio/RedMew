-- In-game tests for the ore mined score. These run on every Danger Ores map with it enabled
-- (the default): ore produced on the map counts towards it, at every quality, and other items
-- don't.
--
-- They add to the player force's production statistics directly, the way mining does.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local OreMined = require 'map_gen.maps.danger_ores.modules.ore_mined'
local RS = require 'map_gen.shared.redmew_surface'

if not DOC.ore_mined.enabled then
    return
end

Declare.module(
    {'map_gen', 'danger ores', 'ore mined'},
    function()
        local function stats()
            return game.forces.player.get_item_production_statistics(RS.get_surface_name())
        end

        Declare.test(
            'ore produced on the map counts as mined',
            function()
                -- Arrange
                local counts, total = OreMined.get_ore_mined()
                local coal = counts['coal']
                Assert.is_true(coal ~= nil, 'coal is not counted as ore')

                -- Act
                stats().on_flow('coal', 100)

                -- Assert
                local after, after_total = OreMined.get_ore_mined()
                Assert.equal(coal + 100, after['coal'], 'coal mined after producing 100')
                Assert.equal(total + 100, after_total, 'ore mined after producing 100 coal')
            end
        )

        Declare.test(
            'other items do not count',
            function()
                -- Arrange
                local _, total = OreMined.get_ore_mined()

                -- Act
                stats().on_flow('iron-plate', 100)

                -- Assert
                local _, after = OreMined.get_ore_mined()
                Assert.equal(total, after, 'ore mined after producing 100 iron plates')
            end
        )

        if prototypes.quality['rare'] then
            Declare.test(
                'quality ore counts too',
                function()
                    -- Arrange
                    local _, total = OreMined.get_ore_mined()

                    -- Act
                    stats().on_flow({name = 'stone', quality = 'rare'}, 10)

                    -- Assert
                    local _, after = OreMined.get_ore_mined()
                    Assert.equal(total + 10, after, 'ore mined after producing 10 rare stone')
                end
            )
        end
    end
)
