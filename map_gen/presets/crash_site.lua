require('map_gen.presets.crash_site.blueprint_extractor')

local b = require 'map_gen.shared.builders'
local Random = require 'map_gen.shared.random'
local OutpostBuilder = require 'map_gen.presets.crash_site.outpost_builder'

local outpost_seed = 1000

local outpost_blocks = 9
local outpost_variance = 3
local outpost_min_step = 2
local outpost_max_level = 4

local striaght_wall = OutpostBuilder.make_4_way(require('map_gen.presets.crash_site.outpost_data.gun_turrent_straight'))
local outer_corner_wall =
    OutpostBuilder.make_4_way(require('map_gen.presets.crash_site.outpost_data.gun_turrent_outer_corner'))
local inner_corner_wall =
    OutpostBuilder.make_4_way(require('map_gen.presets.crash_site.outpost_data.gun_turret_inner_corner'))

local templates = {
    {striaght_wall, outer_corner_wall, inner_corner_wall},
    {[22] = {entity = {name = 'stone-furnace'}}},
    {[22] = {entity = {name = 'assembling-machine-2'}}},
    {[22] = {entity = {name = 'oil-refinery'}}}
}

local outpost_builder = OutpostBuilder.new(outpost_seed)
local shape =
    outpost_builder:do_outpost(outpost_blocks, outpost_variance, outpost_min_step, outpost_max_level, templates)

local pattern = {}
local grid_size = (outpost_blocks + 2) * 6
local half_grid_size = grid_size * 0.5

for r = 1, 100 do
    local row = {}
    pattern[r] = row
    for c = 1, 100 do
        local s =
            outpost_builder:do_outpost(outpost_blocks, outpost_variance, outpost_min_step, outpost_max_level, templates)
        s = b.translate(s, -half_grid_size, -half_grid_size)
        row[c] = s
    end
end

local outposts = b.grid_pattern(pattern, 100, 100, grid_size, grid_size)
local map = b.if_else(outposts, b.full_shape)
map = b.change_tile(map, true, 'grass-1')

return map
