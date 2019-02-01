local b = require 'map_gen.shared.builders'
local Random = require 'map_gen.shared.random'
local math = require 'utils.math'
local table = require 'utils.table'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

local ore_seed1 = 11000
local ore_seed2 = ore_seed1 * 2
local ore_blocks = 100
local ore_block_size = 32

local random_ore = Random.new(ore_seed1, ore_seed2)
local degrees = math.degrees

RS.set_map_gen_settings(
    {
        MGSP.ore_oil_none,
        MGSP.cliff_none
    }
)

local function no_enemies(_, _, world, tile)
    for _, e in ipairs(world.surface.find_entities_filtered({force = 'enemy', position = {world.x, world.y}})) do
        e.destroy()
    end

    return tile
end

local small_ore_patch = b.circle(12)
local medium_ore_patch = b.circle(24)
local big_ore_patch = b.subtract(b.circle(36), b.circle(16))

local ore_patches = {
    {shape = small_ore_patch, weight = 3},
    {shape = medium_ore_patch, weight = 2},
    {shape = big_ore_patch, weight = 1}
}

local total_ore_patch_weights = {}
local square_t = 0
for _, v in ipairs(ore_patches) do
    square_t = square_t + v.weight
    table.insert(total_ore_patch_weights, square_t)
end

local value = b.exponential_value

local function non_transform(shape)
    return shape
end

local function uranium_transform(shape)
    return b.scale(shape, 0.5)
end

local function oil_transform(shape)
    shape = b.scale(shape, 0.5)
    return b.throttle_world_xy(shape, 1, 4, 1, 4)
end

local function empty_transform()
    return b.empty_shape
end

local ores = {
    {transform = non_transform, resource = 'iron-ore', value = value(250, 0.4, 1.1), weight = 16},
    {transform = non_transform, resource = 'copper-ore', value = value(200, 0.4, 1.1), weight = 10},
    {transform = non_transform, resource = 'stone', value = value(125, 0.2, 1.05), weight = 3},
    {transform = non_transform, resource = 'coal', value = value(200, 0.3, 1.075), weight = 5},
    {transform = uranium_transform, resource = 'uranium-ore', value = value(100, 0.3, 1.025), weight = 3},
    {transform = oil_transform, resource = 'crude-oil', value = value(100000, 50, 1.05), weight = 6},
    {transform = empty_transform, weight = 300}
}

local total_ore_weights = {}
local ore_t = 0
for _, v in ipairs(ores) do
    ore_t = ore_t + v.weight
    table.insert(total_ore_weights, ore_t)
end

local function do_resources()
    local pattern = {}

    for r = 1, ore_blocks do
        local row = {}
        pattern[r] = row
        for c = 1, ore_blocks do
            local shape
            local i = random_ore:next_int(1, square_t)
            local index = table.binary_search(total_ore_patch_weights, i)
            if (index < 0) then
                index = bit32.bnot(index)
            end
            shape = ore_patches[index].shape

            local ore_data
            i = random_ore:next_int(1, ore_t)
            index = table.binary_search(total_ore_weights, i)
            if (index < 0) then
                index = bit32.bnot(index)
            end
            ore_data = ores[index]

            shape = ore_data.transform(shape)
            local ore = b.resource(shape, ore_data.resource, ore_data.value)

            row[c] = ore
        end
    end

    local ore_shape = b.grid_pattern_full_overlap(pattern, ore_blocks, ore_blocks, ore_block_size, ore_block_size)
    return ore_shape
end

local map_ores = do_resources()

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

    local worm_chance = d - 160

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

local h_track = {
    b.line_x(2),
    b.translate(b.line_x(2), 0, -3),
    b.translate(b.line_x(2), 0, 3),
    b.rectangle(2, 10)
}

h_track = b.any(h_track)
h_track = b.single_x_pattern(h_track, 15)
h_track = b.change_tile(h_track, true, 'water')

local v_track = {
    b.line_y(2),
    b.translate(b.line_y(2), -3, 0),
    b.translate(b.line_y(2), 3, 0),
    b.rectangle(10, 2)
}

v_track = b.any(v_track)
v_track = b.single_y_pattern(v_track, 15)
v_track = b.change_tile(v_track, true, 'water')

local d_track = {
    b.line_x(2),
    b.translate(b.line_x(3), 0, -3),
    b.translate(b.line_x(3), 0, 3),
    b.rectangle(1, 10)
}

d_track = b.any(d_track)
d_track = b.single_x_pattern(d_track, 15)
d_track = b.change_tile(d_track, true, 'water')

local small_dot = b.circle(96)
local mediumn_dot = b.circle(128)
local big_dot = b.circle(160)

local h_arm = b.line_x(48)
h_arm = b.change_tile(h_arm, true, 'deepwater')
h_arm = b.any {h_track, h_arm}

local v_arm = b.line_y(48)
v_arm = b.change_tile(v_arm, true, 'deepwater')
v_arm = b.any {v_track, v_arm}

local arms = b.any {h_arm, v_arm}

local d1_arm = b.line_x(48)
d1_arm = b.change_tile(d1_arm, true, 'deepwater')
d1_arm = b.any {d_track, d1_arm}
d1_arm = b.rotate(d1_arm, degrees(45))

local d2_arm = b.line_x(48)
d2_arm = b.change_tile(d2_arm, true, 'deepwater')
d2_arm = b.any {d_track, d2_arm}
d2_arm = b.rotate(d2_arm, degrees(-45))

local arms2 = b.any {d1_arm, d2_arm}

local shape = b.any {b.translate(arms2, 480, 0), b.translate(arms2, -480, 0), mediumn_dot, arms}
shape = b.apply_effect(shape, no_enemies)

local shape2 = b.all {big_dot, b.invert(small_dot)}
shape2 = b.choose(big_dot, shape2, b.any {arms, arms2})

local iron = b.circle(16)
iron = b.translate(iron, 0, -96)
--iron = b.rotate(iron, degrees(0))
iron =
    b.resource(
    iron,
    'iron-ore',
    function()
        return 700
    end
)

local copper = b.circle(12)
copper = b.translate(copper, 0, -96)
copper = b.rotate(copper, degrees(72))
copper =
    b.resource(
    copper,
    'copper-ore',
    function()
        return 600
    end
)

local stone = b.circle(8)
stone = b.translate(stone, 0, -96)
stone = b.rotate(stone, degrees(144))
stone =
    b.resource(
    stone,
    'stone',
    function()
        return 1500
    end
)

local coal = b.circle(10)
coal = b.translate(coal, 0, -96)
coal = b.rotate(coal, degrees(216))
coal =
    b.resource(
    coal,
    'coal',
    function()
        return 850
    end
)

local oil = b.circle(5)
oil = b.throttle_xy(oil, 1, 3, 1, 3)
oil = b.translate(oil, 0, -96)
oil = b.rotate(oil, degrees(288))
oil =
    b.resource(
    oil,
    'crude-oil',
    function()
        return 60000
    end
)

local start = b.apply_entity(mediumn_dot, b.any {iron, copper, stone, coal, oil})

local pattern = {
    {shape, b.empty_shape},
    {b.empty_shape, shape}
}
local shape_islands = b.grid_pattern(pattern, 2, 2, 480, 480)

local pattern2 = {
    {b.empty_shape, shape2},
    {shape2, b.empty_shape}
}
local shape2_islands = b.grid_pattern(pattern2, 2, 2, 480, 480)
shape2_islands = b.apply_entity(shape2_islands, map_ores)
shape2_islands = b.apply_entity(shape2_islands, worms)

local map = b.if_else(shape_islands, shape2_islands)

map = b.choose(mediumn_dot, start, map)

map = b.change_map_gen_collision_tile(map, 'water-tile', 'grass-1')

map = b.fish(map, 0.0025)

return map
