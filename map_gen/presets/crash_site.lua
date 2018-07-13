local b = require 'map_gen.shared.builders'
local Random = require 'map_gen.shared.random'
local OutpostBuilder = require 'map_gen.presets.crash_site.outpost_builder'

local outpost_seed = 5000

local outpost_blocks = 9
local outpost_variance = 3
local outpost_min_step = 2
local outpost_max_level = 4

local outpost_builder = OutpostBuilder.new(outpost_seed)

local pattern = {}

for r = 1, 100 do
    local row = {}
    pattern[r] = row
    for c = 1, 100 do
        row[c] = outpost_builder:do_outpost(outpost_blocks, outpost_variance, outpost_min_step, outpost_max_level)
    end
end

local outposts = b.grid_pattern(pattern, 100, 100, 20, 20)
local map = b.apply_entity(b.tile('grass-1'), outposts)

return map
