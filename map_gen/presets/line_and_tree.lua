local b = require 'map_gen.shared.builders'
local table = require 'utils.table'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

local degrees = require "utils.math".degrees

local ore_seed = 4000

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

local ball = b.circle(16)
local line1 = b.translate(b.rectangle(42, 8), 34, 0)
local line2 = b.translate(b.rectangle(8, 42), 0, -34)

local ball_shape = b.any {ball, line1, line2}

local function value(base, mult, pow)
    return function(x, y)
        local d_sq = x * x + y * y
        return base + mult * d_sq ^ ( pow / 2 ) -- d ^ pow
    end
end
local ore_shape = b.circle(5)
local oil_shape = b.throttle_world_xy(b.circle(3), 1, 4, 1, 4)

local ores = {
    {b.resource(ore_shape, 'iron-ore', value(250, 0.75, 1.15)), 16},
    {b.resource(ore_shape, 'copper-ore', value(200, 0.75, 1.15)), 10},
    {b.resource(ore_shape, 'stone', value(350, 0.4, 1.075)), 3},
    {b.resource(ore_shape, 'coal', value(200, 0.8, 1.075)), 8},
    {b.resource(b.circle(3), 'uranium-ore', value(300, 0.3, 1.05)), 3},
    {b.resource(oil_shape, 'crude-oil', value(120000, 50, 1.15)), 6}
    --{b.empty_shape, 52}
}

local total_weights = {}
local t = 0
for _, v in pairs(ores) do
    t = t + v[2]
    table.insert(total_weights, t)
end

local Random = require 'map_gen.shared.random'
local random = Random.new(ore_seed, ore_seed * 2)

local p_cols = 50
local p_rows = 50

local function make_tree()
    local function crop(x, y)
        return x > -32 and y < 32
    end
    local pattern = {}

    for _ = 1, p_rows do
        local row = {}
        table.insert(pattern, row)
        for _ = 1, p_cols do
            local i = random:next_int(1, t)

            local index = table.binary_search(total_weights, i)
            if (index < 0) then
                index = bit32.bnot(index)
            end

            local shape = ores[index][1]

            shape = b.apply_entity(ball_shape, shape)
            shape = b.translate(shape, -16, 16)

            table.insert(row, shape)
        end
    end

    local tree = b.grid_pattern_overlap(pattern, p_cols, p_rows, 64, 64)

    local sea = b.tile('water')
    sea = b.fish(sea, 0.005)

    tree = b.if_else(tree, sea)

    tree = b.choose(crop, tree, b.empty_shape)
    tree = b.translate(tree, 16, -16)

    local line = b.rectangle(36, 8)
    line = b.rotate(line, degrees(45))
    line = b.translate(line, -23, 23)

    tree = b.any {line, tree}

    return tree
end

local tree_left = b.rotate(make_tree(), degrees(135))
tree_left = b.scale(tree_left, 1.5)
tree_left = b.translate(tree_left, -123.6, 0)

local thickness = 96
local function strip(x, y)
    return x > -95 and (y > -(thickness - 1) and y <= thickness - 1)
end

strip = b.apply_effect(strip, no_enemies)

local function outer_strip(x, y)
    return x > -96 and (y > -thickness and y <= thickness)
end

local water_band = b.change_tile(outer_strip, true, 'water')

local map = b.any {tree_left, strip, water_band}

local start_iron =
    b.resource(
    b.full_shape,
    'iron-ore',
    function()
        return 800
    end
)
local start_copper =
    b.resource(
    b.full_shape,
    'copper-ore',
    function()
        return 500
    end
)
local start_coal =
    b.resource(
    b.full_shape,
    'coal',
    function()
        return 600
    end
)
local start_stone =
    b.resource(
    b.full_shape,
    'stone',
    function()
        return 250
    end
)

local start_circle = b.circle(16)
start_circle = b.apply_entity(start_circle, b.segment_pattern {start_iron, start_copper, start_coal, start_stone})
start_circle = b.translate(start_circle, -32, -0)

map = b.any {start_circle, map}

map = b.change_map_gen_collision_tile(map, 'water-tile', 'grass-1')

map = b.scale(map, 3, 3)

return map
