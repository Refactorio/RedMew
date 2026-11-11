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

    Declare.test('there is iron to mine right outside spawn, all round', function()
        -- Arrange: spawn's ore-free circle is 64 tiles across the radius
        local map = build(DOC.map_config, 1)
        local iron, total = 0, 0

        -- Act
        for k = 0, 179 do
            local a = k / 180 * 2 * math.pi
            for r = 66, 90, 6 do
                local tile = map(math.floor(r * math.cos(a)), math.floor(r * math.sin(a)), {})
                total = total + 1
                if tile.entities[1].name == 'iron-ore' then
                    iron = iron + 1
                end
            end
        end

        -- Assert
        Assert.equal(total, iron, 'iron right outside spawn')
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
