local b = require 'map_gen.shared.builders'
local math = require 'utils.math'
local table = require 'utils.table'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

-- change these to change the pattern.
local seed1 = 17000
local seed2 = seed1 * 2

RS.set_map_gen_settings(
    {
        MGSP.ore_oil_none,
        MGSP.peaceful_mode_on,
        MGSP.water_none
    }
)

local function value(base, mult, pow)
    return function(x, y)
        local d_sq = x * x + y * y
        return base + mult * d_sq ^ (pow / 2) -- d ^ pow
    end
end

local big_circle = b.circle(48)
local small_circle = b.circle(24)

local ring = b.all {big_circle, b.invert(small_circle)}

local ores = {
    {resource_type = 'iron-ore', value = value(75, 0.25, 1.15)},
    {resource_type = 'copper-ore', value = value(65, 0.2, 1.15)},
    {resource_type = 'stone', value = value(50, 0.2, 1.1)},
    {resource_type = 'coal', value = value(50, 0.15, 1.1)},
    {resource_type = 'uranium-ore', value = value(50, 0.1, 1.075)},
    {resource_type = 'crude-oil', value = value(17500, 25, 1.15)}
}

local iron = b.resource(b.full_shape, ores[1].resource_type, ores[1].value)
local copper = b.resource(b.full_shape, ores[2].resource_type, ores[2].value)
local stone = b.resource(b.full_shape, ores[3].resource_type, ores[3].value)
local coal = b.resource(b.full_shape, ores[4].resource_type, ores[4].value)
local uranium = b.resource(b.full_shape, ores[5].resource_type, ores[5].value)
local oil = b.resource(b.throttle_world_xy(b.full_shape, 1, 8, 1, 8), ores[6].resource_type, ores[6].value)

local function striped(_, _, world)
    local t = (world.x + world.y) % 4 + 1
    local ore = ores[t]

    return {
        name = ore.resource_type,
        position = {world.x, world.y},
        amount = 5 * ore.value(world.x, world.y)
    }
end

local function sprinkle(_, _, world)
    local t = math.random(1, 4)
    local ore = ores[t]

    return {
        name = ore.resource_type,
        position = {world.x, world.y},
        amount = 5 * ore.value(world.x, world.y)
    }
end

local rock_names = {'rock-big', 'rock-huge', 'sand-rock-big'}
local function rocks_func()
    local rock = rock_names[math.random(#rock_names)]
    return {name = rock}
end

local rocks = b.entity_func(b.throttle_world_xy(b.full_shape, 1, 6, 1, 6), rocks_func)

local segmented = b.segment_pattern({iron, copper, stone, coal})

local tree = b.entity(b.throttle_world_xy(b.full_shape, 1, 3, 1, 3), 'tree-01')

local function constant(x)
    return function()
        return x
    end
end

local tree_shape = b.throttle_world_xy(big_circle, 1, 3, 1, 3)
tree_shape = b.subtract(tree_shape, b.translate(b.circle(6), 0, 32))

local start_iron = b.resource(small_circle, ores[1].resource_type, constant(750))
local start_copper = b.resource(small_circle, ores[2].resource_type, constant(600))
local start_stone = b.resource(small_circle, ores[3].resource_type, constant(600))
local start_coal = b.resource(small_circle, ores[4].resource_type, constant(600))
local start_segmented = b.segment_pattern({start_iron, start_copper, start_stone, start_coal})
local start_tree = b.entity(tree_shape, 'tree-01')

local worm_names = {
    'small-worm-turret',
    'medium-worm-turret',
    'big-worm-turret'
}

local max_worm_chance = 1 / 128
local worm_chance_factor = 1 / (192 * 512)

local function worms(_, _, world)
    local wx, wy = world.x, world.y
    local d = math.sqrt(wx * wx + wy * wy)

    local worm_chance = d - 128

    if worm_chance > 0 then
        worm_chance = worm_chance * worm_chance_factor
        worm_chance = math.min(worm_chance, max_worm_chance)

        if math.random() < worm_chance then
            if d < 256 then
                return {name = 'small-worm-turret'}
            else
                local max_lvl
                local min_lvl
                if d < 512 then
                    max_lvl = 2
                    min_lvl = 1
                else
                    max_lvl = 3
                    min_lvl = 2
                end
                local lvl = math.random() ^ (512 / d) * max_lvl
                lvl = math.ceil(lvl)
                lvl = math.clamp(lvl, min_lvl, 3)
                return {name = worm_names[lvl]}
            end
        end
    end
end

local iron_loop = b.apply_entities(ring, {iron, worms})
local copper_loop = b.apply_entities(ring, {copper, worms})
local stone_loop = b.apply_entities(ring, {stone, worms})
local coal_loop = b.apply_entities(ring, {coal, worms})
local uranium_loop = b.apply_entities(ring, {uranium, worms})
local oil_loop = b.apply_entities(ring, {oil, worms})
local striped_loop = b.apply_entities(ring, {striped, worms})
local sprinkle_loop = b.apply_entities(ring, {sprinkle, worms})
local segmented_loop = b.apply_entities(ring, {segmented, worms})
local tree_loop = b.apply_entities(ring, {tree, worms})
local rock_loop = b.apply_entities(ring, {rocks, worms})
local start_loop = b.apply_entities(big_circle, {start_segmented, start_tree})
start_loop = b.translate(start_loop, 0, -32)

local loops = {
    {striped_loop, 3},
    {sprinkle_loop, 3},
    {segmented_loop, 3},
    {tree_loop, 9},
    {rock_loop, 9},
    {iron_loop, 20},
    {copper_loop, 12},
    {stone_loop, 9},
    {coal_loop, 9},
    {uranium_loop, 1},
    {oil_loop, 9}
}

local Random = require 'map_gen.shared.random'
local random = Random.new(seed1, seed2)

local total_weights = {}
local t = 0
for _, v in ipairs(loops) do
    t = t + v[2]
    table.insert(total_weights, t)
end

local p_cols = 50
local p_rows = 50
local pattern = {}

for c = 1, p_cols do
    local row = {}
    table.insert(pattern, row)
    for r = 1, p_rows do
        if c == 1 and r == 1 then
            table.insert(row, start_loop)
        else
            local i = random:next_int(1, t)

            local index = table.binary_search(total_weights, i)
            if (index < 0) then
                index = bit32.bnot(index)
            end

            local shape = loops[index][1]

            local x = random:next_int(-32, 32)
            local y = random:next_int(-32, 32)

            shape = b.translate(shape, x, y)

            table.insert(row, shape)
        end
    end
end

local map = b.grid_pattern_full_overlap(pattern, p_cols, p_rows, 128, 128)

map = b.change_map_gen_collision_tile(map, 'water-tile', 'grass-1')

local sea = b.change_tile(b.full_shape, true, 'water')
sea = b.fish(sea, 0.00125)

map = b.if_else(map, sea)
return map
