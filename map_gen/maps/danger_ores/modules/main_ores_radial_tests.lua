-- In-game tests for the radial main ores builder: each ore gets its own inner and outer weight,
-- whatever order the sectors are shuffled into. These run whenever main_ores_radial.lua is
-- loaded, i.e. on the Petals preset, and use stand-in tile and ore builders.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local b = require 'map_gen.shared.builders'
local MainOresRadial = require 'map_gen.maps.danger_ores.modules.main_ores_radial'

local SAMPLES = 3600

local RADIAL = {
    from = 200,
    to = 300,
    inner = {['iron-ore'] = 60, ['copper-ore'] = 25, coal = 15},
    outer = {['iron-ore'] = 10, ['copper-ore'] = 60, coal = 30}
}

local function tile_builder()
    return function()
        return 'grass-1'
    end
end

local function ore_builder(name)
    return function()
        return {name = name}
    end
end

local function build(seed, rotate, split_count)
    local config = {
        main_ores = {{name = 'copper-ore', ratios = {}}, {name = 'coal', ratios = {}}, {name = 'iron-ore', ratios = {}}},
        main_ores_radial = RADIAL,
        main_ores_shuffle_order = true,
        main_ores_rotate = rotate,
        main_ores_split_count = split_count
    }
    return MainOresRadial(config)(tile_builder, ore_builder, b.empty_shape, b.empty_shape, game.create_random_generator(1000 + seed))
end

-- The share of a circle of radius d that each ore takes.
local function shares_at(map, d)
    local counts = {}
    for k = 0, SAMPLES - 1 do
        local angle = (k + 0.5) / SAMPLES * 2 * math.pi
        local tile = map(d * math.cos(angle), d * math.sin(angle), {})
        local name = tile.entities[1].name
        counts[name] = (counts[name] or 0) + 1 / SAMPLES
    end
    return counts
end

-- The ores met going once round a circle of radius d, one entry per sector.
local function sectors_round(map, d)
    local names = {}
    for k = 0, SAMPLES - 1 do
        local angle = (k + 0.5) / SAMPLES * 2 * math.pi
        local name = map(d * math.cos(angle), d * math.sin(angle), {}).entities[1].name
        if name ~= names[#names] then
            names[#names + 1] = name
        end
    end
    if #names > 1 and names[1] == names[#names] then
        names[#names] = nil -- the sector the circle started in
    end
    return names
end

local function assert_shares(shares, weights, label)
    for name, weight in pairs(weights) do
        local share = weight / 100
        local actual = shares[name] or 0
        Assert.is_true(math.abs(actual - share) < 0.002, label .. ': ' .. name .. ' takes ' .. actual .. ', expected ' .. share)
    end
end

Declare.module(
    {'map_gen', 'radial sectors', 'builder'},
    function()
        Declare.test(
            'each ore takes its inner weight near spawn and its outer weight far out, for any shuffle',
            function()
                for seed = 1, 6 do
                    -- Arrange
                    local map = build(seed, 30)

                    -- Act
                    local inner, outer = shares_at(map, 150), shares_at(map, 1000)

                    -- Assert
                    assert_shares(inner, RADIAL.inner, 'seed ' .. seed .. ', r=150')
                    assert_shares(outer, RADIAL.outer, 'seed ' .. seed .. ', r=1000')
                end
            end
        )

        Declare.test(
            'a split repeats the sectors without changing the shares, and neighbours never share an ore',
            function()
                for seed = 1, 6 do
                    -- Arrange
                    local map = build(seed, 30, 3)

                    for _, d in ipairs {150, 275, 1000} do
                        -- Act
                        local names = sectors_round(map, d)

                        -- Assert
                        Assert.equal(9, #names, 'seed ' .. seed .. ', r=' .. d .. ': sector count')
                        for i = 1, #names do
                            local after = names[i % #names + 1]
                            Assert.is_true(names[i] ~= after, 'seed ' .. seed .. ', r=' .. d .. ': two ' .. names[i] .. ' sectors touch')
                        end
                    end
                    assert_shares(shares_at(map, 150), RADIAL.inner, 'seed ' .. seed .. ', r=150')
                    assert_shares(shares_at(map, 1000), RADIAL.outer, 'seed ' .. seed .. ', r=1000')
                end
            end
        )

        Declare.test(
            'the same seed builds the same map',
            function()
                -- Arrange
                local a, b2 = build(7, 30), build(7, 30)

                -- Act / Assert
                for k = 0, 359 do
                    local angle = math.rad(k)
                    for _, d in ipairs {100, 250, 800} do
                        local x, y = d * math.cos(angle), d * math.sin(angle)
                        Assert.equal(a(x, y, {}).entities[1].name, b2(x, y, {}).entities[1].name)
                    end
                end
            end
        )
    end
)
