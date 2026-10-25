-- In-game tests for the pure radial sectors layout. These run whenever radial_sectors_layout.lua
-- is loaded, i.e. on the Petals preset. None of them touch the map.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Layout = require 'map_gen.maps.danger_ores.modules.radial_sectors_layout'

local LAYOUT = {from = 200, to = 300, inner = {50, 25, 25}, outer = {10, 50, 40}}
local SAMPLES = 3600

-- The share of a circle of radius d that each sector takes.
local function shares_at(layout, d)
    local counts = {0, 0, 0}
    for k = 0, SAMPLES - 1 do
        local angle = (k + 0.5) / SAMPLES * 2 * math.pi
        local i = Layout.sector_at(layout, d * math.cos(angle), d * math.sin(angle))
        counts[i] = counts[i] + 1
    end
    for i = 1, 3 do
        counts[i] = counts[i] / SAMPLES
    end
    return counts
end

local function assert_shares(actual, expected, label)
    local total = 0
    for i = 1, #expected do
        total = total + expected[i]
    end
    for i = 1, #expected do
        local share = expected[i] / total
        Assert.is_true(math.abs(actual[i] - share) < 0.002,
            label .. ': sector ' .. i .. ' takes ' .. actual[i] .. ', expected ' .. share)
    end
end

Declare.module(
    {'map_gen', 'radial sectors', 'layout'},
    function()
        Declare.test(
            'sectors take the inner weights inside from',
            function()
                -- Act
                local shares = shares_at(LAYOUT, 150)

                -- Assert
                assert_shares(shares, LAYOUT.inner, 'r=150')
            end
        )

        Declare.test(
            'sectors take the outer weights past to',
            function()
                -- Act
                local shares = shares_at(LAYOUT, 1000)

                -- Assert
                assert_shares(shares, LAYOUT.outer, 'r=1000')
            end
        )

        Declare.test(
            'halfway between from and to, sectors take the average of inner and outer',
            function()
                -- Act
                local shares = shares_at(LAYOUT, 250)

                -- Assert
                assert_shares(shares, {30, 37.5, 32.5}, 'r=250')
            end
        )

        Declare.test(
            'the blend is 0 up to from and 1 from to on, and eases in and out between',
            function()
                -- Act / Assert: the ends
                for _, case in ipairs {{0, 0}, {199, 0}, {200, 0}, {250, 0.5}, {300, 1}, {5000, 1}} do
                    local blend = Layout.blend(LAYOUT, case[1])
                    Assert.is_true(math.abs(blend - case[2]) < 1e-9, 'blend at ' .. case[1] .. ' is ' .. blend .. ', expected ' .. case[2])
                end

                -- Act / Assert: flat at both edges, so borders don't kink there, and always rising
                Assert.is_true(Layout.blend(LAYOUT, 201) < 0.001, 'blend starts with a kink')
                Assert.is_true(1 - Layout.blend(LAYOUT, 299) < 0.001, 'blend ends with a kink')
                local previous = 0
                for d = 201, 300 do
                    local blend = Layout.blend(LAYOUT, d)
                    Assert.is_true(blend > previous, 'blend falls at ' .. d)
                    previous = blend
                end
            end
        )

        Declare.test(
            'sectors stay centred, so no border swings more than half the spread',
            function()
                -- Arrange: where each border (sector k to k + 1, in turns) sits on a circle
                local function borders(d)
                    local found = {}
                    local previous = Layout.sector_at(LAYOUT, -d, -1e-9)
                    for k = 1, SAMPLES do
                        local angle = math.pi + k / SAMPLES * 2 * math.pi
                        local i = Layout.sector_at(LAYOUT, d * math.cos(angle), -d * math.sin(angle))
                        if i ~= previous then
                            found[previous] = k / SAMPLES
                            previous = i
                        end
                    end
                    return found
                end

                -- Act
                local near, far = borders(150), borders(1000)

                -- Assert: shares move 0.4, 0.15 and 0 turns uncentred; centred, at most 0.2
                for k = 1, 3 do
                    local move = math.abs(far[k] - near[k])
                    move = math.min(move, 1 - move)
                    Assert.is_true(move <= 0.2 + 2 / SAMPLES, 'border ' .. k .. ' moved ' .. move .. ' turns')
                end
            end
        )

        Declare.test(
            'every position gets a sector, spawn included',
            function()
                -- Act / Assert
                for _, p in ipairs {{0, 0}, {-1, 0}, {1, 0}, {0, 1}, {0, -1}, {-500, -0.001}, {-500, 0.001}} do
                    local i = Layout.sector_at(LAYOUT, p[1], p[2])
                    Assert.is_true(i >= 1 and i <= 3, 'sector ' .. tostring(i) .. ' at ' .. p[1] .. ',' .. p[2])
                end
            end
        )
    end
)
