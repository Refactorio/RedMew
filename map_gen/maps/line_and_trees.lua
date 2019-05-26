local b = require "map_gen.shared.builders"
local table = require 'utils.table'
local RS = require 'map_gen.shared.redmew_surface'
local Event = require 'utils.event'
local MGSP = require 'resources.map_gen_settings'

local degrees = require "utils.math".degrees

local seed1 = 420420
local seed2 = 696969

RS.set_map_gen_settings(
    {
        MGSP.ore_oil_none,
        MGSP.cliff_none
    }
)

local ball = b.circle(16)
local line1 = b.translate(b.rectangle(42, 8), 34, 0)
local line2 = b.translate(b.rectangle(8, 42), 0, -34)

local ball_shape = b.any{ball, line1, line2}

local value = b.manhattan_value
local ore_shape = b.circle(4)
local oil_shape = b.throttle_world_xy(b.circle(2.67), 1, 4, 1, 4)

local ores = {
    {b.resource(ore_shape, "iron-ore", value(1500, 1.5)), 24},
    {b.resource(ore_shape, "copper-ore", value(1200, 1.2)), 12},
    {b.resource(ore_shape, "stone", value(1200, 0.6)), 4},
    {b.resource(ore_shape, "coal", value(1200, 0.6)), 8},
    {b.resource(b.circle(2), "uranium-ore", value(450, 0.6)), 1},
    {b.resource(oil_shape, "crude-oil", value(375000, 188)), 4},
--{b.empty_shape, 52}
}

local total_weights = {}
local t = 0
for _, v in pairs(ores) do
    t = t + v[2]
    table.insert(total_weights, t)
end

local Random = require "map_gen.shared.random"
local random = Random.new(seed1, seed2)

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

    local sea = b.tile("water")
    sea = b.fish(sea, 0.005)

    tree = b.if_else(tree, sea)

    tree = b.choose(crop, tree, b.empty_shape)
    tree = b.translate(tree, 16, -16)

    local line = b.rectangle(36, 8)
    line = b.rotate(line, degrees(45))
    line = b.translate(line, -23, 23)

    tree = b.any{line, tree}

    return tree
end

local tree_top = b.rotate(make_tree(), degrees(45))
tree_top = b.translate(tree_top, 0, -128)

local tree_right = b.rotate(make_tree(), degrees(-45))
tree_right = b.translate(tree_right, 128, 0)

local tree_left = b.rotate(make_tree(), degrees(135))
tree_left = b.translate(tree_left, -128, 0)

local thickness = 96
local function strip(x, y)
    return y > -95 and (x > -(thickness - 1) and x <= thickness - 1)
end

local function outer_strip(x, y)
    return y > -96 and (x > -thickness and x <= thickness)
end

local water_band = b.change_tile(outer_strip, true, "water")

local map = b.any{tree_top, tree_right, tree_left, strip, water_band}

local start_iron = b.resource(b.full_shape, "iron-ore", value(400,0))
local start_copper = b.resource(b.full_shape, "copper-ore", value(250,0))
local start_coal = b.resource(b.full_shape, "coal", value(300,0))
local start_stone = b.resource(b.full_shape, "stone", value(125,0))

local start_circle = b.circle(16)
start_circle = b.apply_entity(start_circle, b.segment_pattern{start_iron, start_copper, start_coal, start_stone})
start_circle = b.translate(start_circle, 0, -32)

map = b.any{start_circle, map}

map = b.change_map_gen_collision_tile(map, "water-tile", "grass-1")

map = b.rotate(map, degrees(90))
map = b.scale(map, 3, 3)

local function on_init()
    game.forces['player'].technologies['landfill'].enabled = false
end
Event.on_init(on_init)

return map
