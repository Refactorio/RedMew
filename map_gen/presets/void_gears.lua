local b = require 'map_gen.shared.builders'
local table = require 'utils.table'
local pic = require 'map_gen.data.presets.void_gears'
local gear = require 'map_gen.data.presets.gear_96by96'
local Random = require 'map_gen.shared.random'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

local seed1 = 6666
local seed2 = 9999

RS.set_map_gen_settings(
    {
        MGSP.ore_oil_none,
        MGSP.cliff_none
    }
)

pic = b.decompress(pic)

local shape = b.picture(pic)
shape = b.invert(shape)

local map = b.single_pattern(shape, pic.width, pic.height)
map = b.translate(map, -102, 133)
map = b.scale(map, 1.75, 1.75)

gear = b.decompress(gear)
local gear_big = b.picture(gear)
local gear_medium = b.scale(gear_big, 2 / 3)
local gear_small = b.scale(gear_big, 1 / 3)

local value = b.manhattan_value

local ores = {
    {resource_type = 'iron-ore', value = value(250, 1.5)},
    {resource_type = 'copper-ore', value = value(250, 1.5)},
    {resource_type = 'stone', value = value(250, 1)},
    {resource_type = 'coal', value = value(250, 1)},
    {resource_type = 'uranium-ore', value = value(125, 1)},
    {resource_type = 'crude-oil', value = value(50000, 250)}
}
local function striped(shape) -- luacheck: ignore 431
    return function(x, y, world)
        if not shape(x, y) then
            return nil
        end

        local t = (world.x + world.y) % 4 + 1
        local ore = ores[t]

        return {
            name = ore.resource_type,
            position = {world.x, world.y},
            amount = 3 * ore.value(world.x, world.y)
        }
    end
end

local function sprinkle(shape) -- luacheck: ignore 431
    return function(x, y, world)
        if not shape(x, y) then
            return nil
        end

        local t = math.random(1, 4)
        local ore = ores[t]

        return {
            name = ore.resource_type,
            position = {world.x, world.y},
            amount = 3 * ore.value(world.x, world.y)
        }
    end
end

local function radial(shape, radius) -- luacheck: ignore 431
    local stone_r_sq = radius * 0.3025 -- radius * 0.55
    local coal_r_sq = radius * 0.4225 -- radius * 0.65
    local copper_r_sq = radius * 0.64 -- radius * 0.8

    return function(x, y, world)
        if not shape(x, y) then
            return nil
        end

        local d_sq = x * x + y * y

        local ore
        if d_sq < stone_r_sq then
            ore = ores[4]
        elseif d_sq < coal_r_sq then
            ore = ores[3]
        elseif d_sq < copper_r_sq then
            ore = ores[2]
        else
            ore = ores[1]
        end

        return {
            name = ore.resource_type,
            position = {world.x, world.y},
            amount = 3 * ore.value(world.x, world.y)
        }
    end
end

local big_patches = {
    {b.no_entity, 220},
    {b.resource(gear_big, ores[1].resource_type, ores[1].value), 20},
    {b.resource(gear_big, ores[2].resource_type, ores[2].value), 12},
    {b.resource(gear_big, ores[3].resource_type, ores[3].value), 4},
    {b.resource(gear_big, ores[4].resource_type, ores[4].value), 6},
    {b.resource(gear_big, ores[5].resource_type, ores[5].value), 2},
    {b.resource(b.throttle_world_xy(gear_big, 1, 8, 1, 8), ores[6].resource_type, ores[6].value), 6},
    {striped(gear_big), 1},
    {sprinkle(gear_big), 1},
    {radial(gear_big, 48), 1}
}
big_patches[#big_patches + 1] = {
    b.segment_pattern({big_patches[2][1], big_patches[3][1], big_patches[4][1], big_patches[5][1]}),
    1
}

local medium_patches = {
    {b.no_entity, 150},
    {b.resource(gear_medium, ores[1].resource_type, ores[1].value), 20},
    {b.resource(gear_medium, ores[2].resource_type, ores[2].value), 12},
    {b.resource(gear_medium, ores[3].resource_type, ores[3].value), 4},
    {b.resource(gear_medium, ores[4].resource_type, ores[4].value), 6},
    {b.resource(gear_medium, ores[5].resource_type, ores[5].value), 2},
    {b.resource(b.throttle_world_xy(gear_medium, 1, 8, 1, 8), ores[6].resource_type, ores[6].value), 6},
    {striped(gear_medium), 1},
    {sprinkle(gear_medium), 1},
    {radial(gear_medium, 32), 1}
}
medium_patches[#medium_patches + 1] = {
    b.segment_pattern({medium_patches[2][1], medium_patches[3][1], medium_patches[4][1], medium_patches[5][1]}),
    1
}

local small_patches = {
    {b.no_entity, 85},
    {b.resource(gear_small, ores[1].resource_type, value(350, 2)), 20},
    {b.resource(gear_small, ores[2].resource_type, value(350, 2)), 12},
    {b.resource(gear_small, ores[3].resource_type, value(350, 2)), 4},
    {b.resource(gear_small, ores[4].resource_type, value(350, 2)), 6},
    {b.resource(gear_small, ores[5].resource_type, value(250, 2)), 2},
    {b.resource(b.throttle_world_xy(gear_small, 1, 4, 1, 4), ores[6].resource_type, ores[6].value), 6},
    {striped(gear_small), 1},
    {sprinkle(gear_small), 1},
    {radial(gear_small, 16), 1}
}
small_patches[#small_patches + 1] = {
    b.segment_pattern({small_patches[2][1], small_patches[3][1], small_patches[4][1], small_patches[5][1]}),
    1
}

local random = Random.new(seed1, seed2)

local p_cols = 50
local p_rows = 50
local function do_patches(patches, offset)
    local total_weights = {}
    local t = 0
    for _, v in ipairs(patches) do
        t = t + v[2]
        table.insert(total_weights, t)
    end

    local pattern = {}

    for _ = 1, p_cols do
        local row = {}
        table.insert(pattern, row)
        for _ = 1, p_rows do
            local i = random:next_int(1, t)

            local index = table.binary_search(total_weights, i)
            if (index < 0) then
                index = bit32.bnot(index)
            end

            local shape = patches[index][1] -- luacheck: ignore 431

            local x = random:next_int(-offset, offset)
            local y = random:next_int(-offset, offset)

            shape = b.translate(shape, x, y)

            table.insert(row, shape)
        end
    end

    return pattern
end

big_patches = do_patches(big_patches, 96)
big_patches = b.grid_pattern_full_overlap(big_patches, p_cols, p_rows, 192, 192)

medium_patches = do_patches(medium_patches, 64)
medium_patches = b.grid_pattern_full_overlap(medium_patches, p_cols, p_rows, 128, 128)

small_patches = do_patches(small_patches, 32)
small_patches = b.grid_pattern_full_overlap(small_patches, p_cols, p_rows, 64, 64)

--map = b.apply_entity(map, small_patches)
map = b.apply_entities(map, {big_patches, medium_patches, small_patches})

local start_stone =
    b.resource(
    gear_big,
    'stone',
    function()
        return 400
    end
)
local start_coal =
    b.resource(
    gear_big,
    'coal',
    function()
        return 800
    end
)
local start_copper =
    b.resource(
    gear_big,
    'copper-ore',
    function()
        return 800
    end
)
local start_iron =
    b.resource(
    gear_big,
    'iron-ore',
    function()
        return 1600
    end
)
local start_segmented = b.segment_pattern({start_stone, start_coal, start_copper, start_iron})
local start_gear = b.apply_entity(gear_big, start_segmented)

map = b.if_else(start_gear, map)

return map
