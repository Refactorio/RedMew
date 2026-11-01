-- In-game tests for the Randomizer, on the Randomizer map: every mix of layout, water and overlay
-- comes up for some seed, the map is built from the mix its seed picks, and every mix makes a map
-- that can be played: land around spawn, and every main ore near it.
--
-- The mixes are built from their config like the map is, and their shapes read tile by tile,
-- without generating chunks, so every mix is checked whatever the map's own seed.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local Layouts = require 'map_gen.maps.danger_ores.modules.layouts'
local Map = require 'map_gen.maps.danger_ores.modules.map'
local Randomizer = require 'map_gen.maps.danger_ores.modules.randomizer'
local RS = require 'map_gen.shared.redmew_surface'

-- how far from spawn every main ore has to show up, as on every Danger Ores map
local REACH = 256
-- tiles between the points read
local STEP = 8
-- around spawn, at least this share of the ground has to be land
local SPAWN_RADIUS, SPAWN_LAND = 48, 0.5

local not_land = {['out-of-map'] = true, water = true, deepwater = true, ['water-green'] = true, ['deepwater-green'] = true}

local function main_ore_names(config)
    local names = {}
    for _, ore in pairs(config.main_ores) do
        local name = ore.name
        local prototype = name and prototypes.entity[name]
        if prototype and prototype.type == 'resource' then
            names[name] = true
        end
    end
    return names
end

--- Reads `shape` around spawn. @return the main ores it doesn't have within REACH, and the share
-- of land within SPAWN_RADIUS
local function survey(shape, ores)
    local missing = {}
    for name in pairs(ores) do
        missing[name] = true
    end
    local land, near = 0, 0
    local world = {surface = RS.get_surface()}
    for x = -REACH, REACH, STEP do
        for y = -REACH, REACH, STEP do
            world.x, world.y = x, y
            local tile = shape(x + 0.5, y + 0.5, world)
            local name = tile
            if type(tile) == 'table' then
                name = tile.tile
                for _, entity in pairs(tile.entities or {}) do
                    missing[entity.name] = nil
                end
            end
            if x * x + y * y <= SPAWN_RADIUS * SPAWN_RADIUS then
                near = near + 1
                if name and not not_land[name] then
                    land = land + 1
                end
            end
        end
    end
    local names = {}
    for name in pairs(missing) do
        names[#names + 1] = name
    end
    table.sort(names)
    return names, land / near
end

--- Every map_config key some recipe sets.
local function changed_keys()
    local keys = {}
    for _, list in pairs({Randomizer.layouts, Randomizer.waters, Randomizer.overlays}) do
        for _, recipe in pairs(list) do
            for key in pairs(recipe.settings) do
                keys[key] = true
            end
        end
    end
    return keys
end

--- What `key` should read on a map of `mix`: the last of its recipes that sets it, else the
-- preset's.
local function expected(base, mix, key)
    local value = base[key]
    for _, recipe in ipairs(mix) do
        local v = recipe.settings[key]
        if v == Layouts.NONE then
            value = nil
        elseif v ~= nil then
            value = v
        end
    end
    return value
end

Declare.module({'map_gen', 'danger ores', 'randomizer'}, function()
    Declare.test('every mix comes up for some seed', function()
        -- Act
        local seen, count = {}, 0
        for seed = 1, 20000 do
            local mix = Randomizer.pick(seed)
            if not seen[mix] then
                seen[mix] = true
                count = count + 1
            end
        end

        -- Assert
        Assert.equal(#Randomizer.combinations, count, 'mixes picked by seeds 1 to 20000')
    end)

    Declare.test('a mix reads as its recipes set, and as the preset otherwise', function()
        local base = Randomizer.base_config
        for _, mix in pairs(Randomizer.combinations) do
            -- Arrange
            local config = Randomizer.map_config(base, function()
                return mix
            end)

            for key in pairs(changed_keys()) do
                -- Act
                local actual = config[key]

                -- Assert
                Assert.is_true(actual == expected(base, mix, key), Randomizer.describe(mix) .. ': map_config.' .. key .. ' is not what the mix makes it')
            end
        end
    end)

    Declare.test('the map is built from the mix its seed picks', function()
        -- Arrange
        local mix = Randomizer.rolled()

        for key in pairs(changed_keys()) do
            -- Act
            local actual = DOC.map_config[key]

            -- Assert
            Assert.is_true(actual == expected(Randomizer.base_config, mix, key), Randomizer.describe(mix) .. ': map_config.' .. key .. ' is not what the mix makes it')
        end
    end)

    Declare.test('every mix makes a map with land around spawn and every main ore near it', function()
        local base = Randomizer.base_config
        for _, mix in pairs(Randomizer.combinations) do
            -- Arrange
            local config = Randomizer.map_config(base, function()
                return mix
            end)

            -- Act
            local shape = Map.build(config, game.create_random_generator(12345))
            local missing, land = survey(shape, main_ore_names(config))

            -- Assert
            local what = Randomizer.describe(mix)
            Assert.is_true(#missing == 0, what .. ': not within ' .. REACH .. ' tiles of spawn: ' .. table.concat(missing, ', '))
            Assert.is_true(land >= SPAWN_LAND, what .. ': only ' .. math.floor(land * 100) .. '% land within ' .. SPAWN_RADIUS .. ' tiles of spawn')
        end
    end)
end)
