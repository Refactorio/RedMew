-- In-game tests for Mosaic, the Danger Ores preset whose ores are a mural of space and industry.
-- These run when it is the active map. They build the map with the real builder and the preset's
-- own config, with stand-in tile and ore builders, and read which ore each tile gets.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local b = require 'map_gen.shared.builders'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local MainOresMosaic = require 'map_gen.maps.danger_ores.modules.main_ores_mosaic'


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

local function build(config, seed)
    return MainOresMosaic(config)(tile_builder, ore_builder, b.empty_shape, b.empty_shape, game.create_random_generator(1000 + seed))
end

Declare.module({'map_gen', 'mosaic'}, function()
    Declare.test('every main ore lies in the land open at the start, on any seed', function()
        -- the square terraforming opens first
        local half = DOC.terraforming.start_size / 2
        for seed = 1, 5 do
            -- Arrange
            local map = build(DOC.map_config, seed)
            local found = {}

            -- Act
            for x = -half, half - 1, 7 do
                for y = -half, half - 1, 7 do
                    found[map(x, y, {}).entities[1].name] = true
                end
            end

            -- Assert
            for _, ore in ipairs(DOC.map_config.main_ores) do
                Assert.is_true(found[ore.name], 'seed ' .. seed .. ': no ' .. ore.name .. ' near spawn')
            end
        end
    end)

    Declare.test('there is iron and copper to mine right outside spawn, all round', function()
        -- Arrange: spawn's ore-free circle is 64 tiles across the radius
        local map = build(DOC.map_config, 1)
        local counts, total = {}, 0

        -- Act: in every eighth of the way round, both
        local both = 0
        for eighth = 0, 7 do
            local seen = {}
            for k = 0, 44 do
                local a = (eighth + k / 45) / 8 * 2 * math.pi
                for r = 66, 90, 6 do
                    local name = map(math.floor(r * math.cos(a)), math.floor(r * math.sin(a)), {}).entities[1].name
                    counts[name] = (counts[name] or 0) + 1
                    total = total + 1
                    seen[name] = true
                end
            end
            if seen['iron-ore'] and seen['copper-ore'] then
                both = both + 1
            end
        end

        -- Assert
        local text = ('%d iron, %d copper of %d'):format(counts['iron-ore'] or 0, counts['copper-ore'] or 0, total)
        Assert.equal(total, (counts['iron-ore'] or 0) + (counts['copper-ore'] or 0), 'only iron and copper: ' .. text)
        Assert.equal(8, both, 'iron and copper in every eighth: ' .. text)
    end)

    Declare.test('an ink that is not a main ore is refused', function()
        -- Arrange
        local config = {
            main_ores = DOC.map_config.main_ores,
            main_ores_mosaic = {inks = {{'uranium-ore', 1}}}
        }

        -- Act
        local ok, message = pcall(build, config, 1)

        -- Assert
        Assert.is_true(not ok, 'a mosaic with uranium ink was built')
        Assert.is_true(message:find('uranium-ore', 1, true) ~= nil, message)
    end)
end)
