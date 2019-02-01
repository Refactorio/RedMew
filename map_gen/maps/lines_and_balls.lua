local b = require 'map_gen.shared.builders'
local Random = require 'map_gen.shared.random'
local table = require 'utils.table'
local math = require "utils.math"
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

local degrees = math.degrees

RS.set_map_gen_settings(
    {
        MGSP.ore_oil_none,
        MGSP.cliff_none
    }
)

local seed1 = 17000
local seed2 = seed1 * 2

local ore_blocks = 100
local ore_block_size = 32

local random_ore = Random.new(seed1, seed2)

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

    return b.grid_pattern_full_overlap(pattern, ore_blocks, ore_blocks, ore_block_size, ore_block_size)
end

local map_ores = do_resources()

local big_circle = b.circle(150)
local small_circle = b.circle(140)
local crop = b.rectangle(300, 150)
crop = b.translate(crop, 0, -75)
local arc = b.all {big_circle, b.invert(small_circle), b.invert(crop)}
arc = b.scale(arc, 6, 2)

local rectangle = b.rectangle(25, 40)

local function h_arc()
    local circle = b.circle(100)
    circle = b.apply_entity(circle, map_ores)
    local ball1 = b.translate(circle, 0, 410)
    local ball2 = b.translate(circle, -460, 370)
    local ball3 = b.translate(circle, 460, 370)
    local arm1 = b.translate(rectangle, 0, 310)
    local arm2 = b.translate(rectangle, -460, 270)
    local arm3 = b.translate(rectangle, 460, 270)

    return b.any {arc, ball1, ball2, ball3, arm1, arm2, arm3}
end

local div_100_sqrt2 = 100 / math.sqrt2
local function v_arc()
    local circle = b.circle(div_100_sqrt2)
    circle = b.apply_entity(circle, map_ores)
    local ball1 = b.translate(circle, -0, 385)
    local ball2 = b.translate(circle, -460, 345)
    local ball3 = b.translate(circle, 460, 345)
    local arm1 = b.translate(rectangle, 0, 305)
    local arm2 = b.translate(rectangle, -460, 265)
    local arm3 = b.translate(rectangle, 460, 265)

    return b.any {arc, ball1, ball2, ball3, arm1, arm2, arm3}
end

local arc1 = h_arc()
arc1 = b.single_pattern(arc1, 1380, 1380)

local arc2 = v_arc()
arc2 = b.single_pattern(arc2, 1380, 1380)
arc2 = b.rotate(arc2, degrees(45))
arc2 = b.scale(arc2, math.sqrt2, math.sqrt2)
arc2 = b.translate(arc2, -165, -688)

local map = b.any {arc1, arc2}

--map = b.apply_entity(map, map_ores)

map = b.translate(map, 0, -414)

local function constant(x)
    return function()
        return x
    end
end

small_circle = b.circle(32)
local start_iron = b.resource(small_circle, ores[1].resource, constant(900))
local start_copper = b.resource(small_circle, ores[2].resource, constant(600))
local start_stone = b.resource(small_circle, ores[3].resource, constant(400))
local start_coal = b.resource(small_circle, ores[4].resource, constant(700))
local start_segmented = b.segment_pattern({start_iron, start_copper, start_stone, start_coal})

local start_shape = b.change_map_gen_collision_tile(small_circle, 'water-tile', 'grass-1')
start_shape = b.apply_entity(start_shape, start_segmented)
start_shape = b.translate(start_shape, 0, 48)
start_shape = b.any {start_shape, b.full_shape}

map = b.choose(b.circle(100), start_shape, map)

return map
