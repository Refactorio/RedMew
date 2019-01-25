local b = require 'map_gen.shared.builders'
local table = require 'utils.table'
local Random = require 'map_gen.shared.random'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

local seed1 = 320420
local seed2 = 420320

RS.set_map_gen_settings(
    {
        MGSP.ore_oil_none,
        MGSP.cliff_none
    }
)

local patch = b.rectangular_spiral(5)
local bounds = b.rectangle(46, 43)
bounds = b.translate(bounds, 0, 3)
patch = b.all {bounds, patch}

local small_patch = b.rectangular_spiral(5)
local small_bounds = b.rectangle(25, 33)
small_bounds = b.translate(small_bounds, -1, -2)
small_patch = b.all {small_bounds, small_patch}

local value = b.manhattan_value

local empty = function()
    return nil
end
local iron = b.resource(patch, 'iron-ore', value(250, 3))
local copper = b.resource(patch, 'copper-ore', value(250, 3))
local stone = b.resource(patch, 'stone', value(250, 2))
local coal = b.resource(patch, 'coal', value(250, 2))
local uranium = b.resource(small_patch, 'uranium-ore', value(125, 2))
local oil = b.resource(b.throttle_world_xy(small_patch, 1, 5, 1, 5), 'crude-oil', value(50000, 250))

local patches = {
    {empty, 300},
    {iron, 20},
    {copper, 12},
    {stone, 4},
    {coal, 6},
    {uranium, 2},
    {oil, 4}
}

local random = Random.new(seed1, seed2)

local total_weights = {}
local t = 0
for _, v in ipairs(patches) do
    t = t + v[2]
    table.insert(total_weights, t)
end

local p_cols = 50
local p_rows = 50
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

        local shape = patches[index][1]

        local flip = random:next_int(1, 4)
        if flip == 2 then
            shape = b.flip_x(shape)
        elseif flip == 3 then
            shape = b.flip_y(shape)
        elseif flip == 4 then
            shape = b.flip_xy(shape)
        end

        table.insert(row, shape)
    end
end

patches = b.grid_pattern(pattern, p_cols, p_rows, 96, 96)

local spiral = b.rectangular_spiral(96)

local map = b.apply_entity(spiral, patches)

local start_iron = b.resource(b.full_shape, 'stone', function() return 800 end)
local start_copper = b.resource(b.full_shape, 'coal', function() return 400 end)
local start_stone = b.resource(b.full_shape, 'copper-ore', function() return 800 end)
local start_coal = b.resource(b.full_shape, 'iron-ore', function() return 1600 end)
local start_spiral = b.segment_pattern({start_iron, start_copper, start_stone, start_coal})

start_spiral = b.apply_entity(patch, start_spiral)
start_spiral = b.any{start_spiral, b.full_shape}
start_spiral = b.translate(start_spiral, 0, -5)

map = b.choose(b.rectangle(96), start_spiral, map)

map = b.change_map_gen_collision_tile(map, 'water-tile', 'grass-1')

local sea = b.tile('water')
sea = b.fish(sea, 0.00125)

map = b.if_else(map, sea)

return map
