-- In-game tests for Bloom, the Danger Ores preset whose sector sizes and richness both change with
-- the distance from spawn. These run when it is the active map and check its sizes and richness
-- against each other: together they must give each ore the share fitted for 1000 satellites, the
-- one Petals gets from sizes alone and Riches from richness alone. The sectors are built by the
-- real radial builder with stand-in tile and ore builders; the richness is read from the real ores.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local b = require 'map_gen.shared.builders'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local Factory = require 'map_gen.maps.danger_ores.config.main_ores_factory'
local MainOresRadial = require 'map_gen.maps.danger_ores.modules.main_ores_radial'

local SAMPLES = 3600

-- The fitted share of each ore, in percent: near spawn for research and building, far out for rockets.
local FITTED = {
    inner = {['iron-ore'] = 51, ['copper-ore'] = 26, coal = 23},
    outer = {['iron-ore'] = 10, ['copper-ore'] = 55, coal = 35}
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

local function build_sectors()
    local config = DOC.map_config
    local radial = {
        main_ores = config.main_ores,
        main_ores_radial = config.main_ores_radial,
        main_ores_split_count = config.main_ores_split_count
    }
    return MainOresRadial(radial)(tile_builder, ore_builder, b.empty_shape, b.empty_shape, game.create_random_generator(1))
end

-- The share of a circle of radius d that each ore's sectors take.
local function shares_at(map, d)
    local shares = {}
    for k = 0, SAMPLES - 1 do
        local angle = (k + 0.5) / SAMPLES * 2 * math.pi
        local name = map(d * math.cos(angle), d * math.sin(angle), {}).entities[1].name
        shares[name] = (shares[name] or 0) + 1 / SAMPLES
    end
    return shares
end

-- How much richer each ore's sector is at distance d than on the standard map.
local function multipliers_at(d)
    local standard = Factory.default()
    local multipliers = {}
    for i, entry in ipairs(DOC.map_config.main_ores) do
        local world = {x = 0, y = d}
        local amount = entry.ratios[1].resource(0, d, world).amount
        multipliers[entry.name] = amount / standard[i].ratios[1].resource(0, d, world).amount
    end
    return multipliers
end

-- The ore each sector gives at distance d compared with the standard map: its share times its richness.
local function supply_at(map, d)
    local shares, multipliers = shares_at(map, d), multipliers_at(d)
    local supply = {}
    for name, multiplier in pairs(multipliers) do
        supply[name] = (shares[name] or 0) * multiplier
    end
    return supply
end

Declare.module(
    {'map_gen', 'bloom'},
    function()
        Declare.test(
            'sizes times richness give each ore its fitted share near spawn and far out',
            function()
                -- Arrange
                local map = build_sectors()

                for _, case in ipairs {{100, FITTED.inner}, {600, FITTED.outer}} do
                    -- Act
                    local supply = supply_at(map, case[1])

                    -- Assert
                    for name, percent in pairs(case[2]) do
                        local actual = supply[name] * 100
                        Assert.is_true(math.abs(actual - percent) < 1, name .. ' at ' .. case[1] .. ' is ' .. actual .. '%, expected ' .. percent .. '%')
                    end
                end
            end
        )

        Declare.test(
            'rings in the blend hold at most 6% less ore than the standard map, and never more',
            function()
                -- Arrange
                local map = build_sectors()

                for d = 200, 350, 10 do
                    -- Act
                    local total = 0
                    for _, s in pairs(supply_at(map, d)) do
                        total = total + s
                    end

                    -- Assert
                    Assert.is_true(total > 0.94 and total < 1.005, 'the ring at ' .. d .. ' holds ' .. total .. ' of the standard ore')
                end
            end
        )
    end
)
