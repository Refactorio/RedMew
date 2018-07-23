require 'map_gen.presets.crash_site.blueprint_extractor'
require 'map_gen.presets.crash_site.entity_died_events'
require 'map_gen.presets.crash_site.weapon_balance'

local b = require 'map_gen.shared.builders'
local Global = require('utils.global')
local Random = require 'map_gen.shared.random'
local OutpostBuilder = require 'map_gen.presets.crash_site.outpost_builder'

local outpost_seed = 1000

local outpost_blocks = 9
local outpost_variance = 3
local outpost_min_step = 2
local outpost_max_level = 4

local outpost_builder = OutpostBuilder.new(outpost_seed)

local walls = require 'map_gen.presets.crash_site.outpost_data.walls'
local thin_walls = require 'map_gen.presets.crash_site.outpost_data.thin_walls'

local light_gun_turrets = require 'map_gen.presets.crash_site.outpost_data.light_gun_turrets'
local medium_gun_turrets = require 'map_gen.presets.crash_site.outpost_data.medium_gun_turrets'
local heavy_gun_turrets = require 'map_gen.presets.crash_site.outpost_data.heavy_gun_turrets'
local light_flame_turrets = require 'map_gen.presets.crash_site.outpost_data.light_flame_turrets'
local laser_turrets = require 'map_gen.presets.crash_site.outpost_data.light_laser_turrets'
local small_worm_turrets = require 'map_gen.presets.crash_site.outpost_data.small_worm_turrets'

local medium_gun_turrets_player = OutpostBuilder.extend_walls(medium_gun_turrets, {force = 'player'})
local laser_turrets_player =
    OutpostBuilder.extend_walls(
    laser_turrets,
    {
        force = 'player',
        turret = {callback = OutpostBuilder.power_source_callback, data = {buffer_size = 24, power_production = 4}}
    }
)

local gear_factory = require 'map_gen.presets.crash_site.outpost_data.gear_factory'
local iron_plate_factory = require 'map_gen.presets.crash_site.outpost_data.iron_plate_factory'
local oil_refinery_factory = require 'map_gen.presets.crash_site.outpost_data.oil_refinery_factory'

local grid_size = (outpost_blocks + 2) * 6
local half_grid_size = grid_size * 0.5

local et = OutpostBuilder.empty_template

local base_templates = {
    test = {
        {[22] = {entity = {name = 'stone-furnace'}}},
        {[22] = {entity = {name = 'assembling-machine-2'}}},
        {[22] = {entity = {name = 'oil-refinery'}}}
    }
}

local templates = {
    {medium_gun_turrets_player},
    {gear_factory[1]},
    {gear_factory[2]},
    {gear_factory[3]}
    --{gear_factory[2]}
    --{base_templates.test[1]}
}

local pattern = {}
for r = 1, 100 do
    local row = {}
    pattern[r] = row
    for c = 1, 100 do
        row[c] =
            outpost_builder:do_outpost(outpost_blocks, outpost_variance, outpost_min_step, outpost_max_level, templates)
    end
end

local outposts = b.grid_pattern(pattern, 100, 100, grid_size, grid_size)
outposts = b.if_else(outposts, b.full_shape)

local thin_walls_player = OutpostBuilder.extend_walls(thin_walls, {force = 'player'})

local outpost =
    outpost_builder.to_shape(
    {
        size = 2,
        laser_turrets_player[1][1],
        gear_factory[1],
        gear_factory[2]
    }
)

local map = b.change_tile(outposts, true, 'grass-1')

--return b.full_shape
return map
--return outpost
