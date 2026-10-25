-- In-game tests for radial richness curves. These run whenever radial_richness.lua is loaded,
-- i.e. on the Riches preset. None of them touch the map: curves are built with the real ore
-- factory and checked by what they give at a few positions.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Factory = require 'map_gen.maps.danger_ores.config.main_ores_factory'
local RadialRichness = require 'map_gen.maps.danger_ores.modules.radial_richness'

local function flat(x, y) -- luacheck: ignore 212
    return 100
end

local PARAMS = {base = flat, inner = 1.5, outer = 0.5, from = 200, to = 300}

local function near(actual, expected, what)
    Assert.is_true(math.abs(actual - expected) < 1e-9, what .. ' is ' .. actual .. ', expected ' .. expected)
end

Declare.module(
    {'map_gen', 'radial richness'},
    function()
        Declare.test(
            'the multiplier is inner up to from, outer from to on, and their average halfway',
            function()
                -- Act / Assert
                for _, case in ipairs {{0, 1.5}, {200, 1.5}, {250, 1}, {300, 0.5}, {5000, 0.5}} do
                    near(RadialRichness.multiplier(PARAMS, case[1]), case[2], 'multiplier at ' .. case[1])
                end
            end
        )

        Declare.test(
            'the multiplier eases in and out, so the ore has no step',
            function()
                -- Act / Assert: flat at both edges, and always moving the same way between
                Assert.is_true(1.5 - RadialRichness.multiplier(PARAMS, 201) < 0.001, 'starts with a step')
                Assert.is_true(RadialRichness.multiplier(PARAMS, 299) - 0.5 < 0.001, 'ends with a step')
                local previous = 1.5
                for d = 201, 300 do
                    local m = RadialRichness.multiplier(PARAMS, d)
                    Assert.is_true(m < previous, 'multiplier rises at ' .. d)
                    previous = m
                end
            end
        )

        Declare.test(
            'the curve is the base times the multiplier at that distance',
            function()
                -- Arrange
                local curve = RadialRichness.curve(PARAMS)

                -- Act / Assert
                near(curve(0, 100), 150, 'at 0,100')
                near(curve(-150, 200), 100, 'at -150,200 (250 away)')
                near(curve(600, -800), 50, 'at 600,-800')
            end
        )

        Declare.test(
            'without a base the curve scales the standard richness',
            function()
                -- Arrange
                local standard = Factory.default()
                local config = Factory.default():richness(RadialRichness.curve {inner = 2, outer = 3, from = 200, to = 300}, 'iron-ore')

                -- Act / Assert
                for i, entry in ipairs(config) do
                    if entry.name == 'iron-ore' then
                        for _, y in ipairs {100, 1000} do
                            local world = {x = 0, y = y}
                            local amount = entry.ratios[1].resource(0, y, world).amount
                            local expected = standard[i].ratios[1].resource(0, y, world).amount * (y < 200 and 2 or 3)
                            near(amount, expected, 'iron sector at ' .. y)
                        end
                    end
                end
            end
        )

        Declare.test(
            'a sector given the curve applies it to every ore in its mix, and other sectors keep theirs',
            function()
                -- Arrange
                local standard = Factory.default()
                local config = Factory.default():richness(RadialRichness.curve {base = flat, inner = 2, outer = 3, from = 200, to = 300}, 'iron-ore')

                -- Act / Assert
                for i, entry in ipairs(config) do
                    for j, ratio in ipairs(entry.ratios) do
                        for _, p in ipairs {{0, 100}, {0, 1000}} do
                            local x, y = p[1], p[2]
                            local amount = ratio.resource(x, y, {x = x, y = y}).amount
                            local expected
                            if entry.name == 'iron-ore' then
                                expected = y < 200 and 200 or 300
                            else
                                expected = standard[i].ratios[j].resource(x, y, {x = x, y = y}).amount
                            end
                            near(amount, expected, entry.name .. ' sector ' .. ratio.resource(x, y, {x = x, y = y}).name .. ' at ' .. y)
                        end
                    end
                end
            end
        )
    end
)
