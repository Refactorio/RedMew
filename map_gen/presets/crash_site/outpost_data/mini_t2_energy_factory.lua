local ob = require 'map_gen.presets.crash_site.outpost_builder'
local Token = require 'utils.token'

local loot = {
    {weight = 10},
    {stack = {name = 'coin', count = 100, distance_factor = 1 / 8}, weight = 5},
    {stack = {name = 'medium-electric-pole', count = 25, distance_factor = 1 / 24}, weight = 3},
    {stack = {name = 'big-electric-pole', count = 25, distance_factor = 1 / 24}, weight = 1},
    {stack = {name = 'substation', count = 5, distance_factor = 1 / 32}, weight = 1},
    {stack = {name = 'solar-panel', count = 25, distance_factor = 1 / 25}, weight = 3},
    {stack = {name = 'accumulator', count = 21, distance_factor = 1 / 21}, weight = 3}
}

local weights = ob.prepare_weighted_loot(loot)

local loot_callback =
    Token.register(
    function(chest)
        ob.do_random_loot(chest, weights, loot)
    end
)

local factory_loot = {
    {stack = {name = 'solar-panel', count = 25, distance_factor = 1 / 25}, weight = 3},
    {stack = {name = 'accumulator', count = 21, distance_factor = 1 / 21}, weight = 3}
}

local factory_weights = ob.prepare_weighted_loot(factory_loot)

local factory_callback =
    Token.register(
    function(factory)
        ob.do_factory_loot(factory, factory_weights, factory_loot)
    end
)

local wall_chests = require 'map_gen.presets.crash_site.outpost_data.mini_wall_chests'
local turret = require 'map_gen.presets.crash_site.outpost_data.mini_gun_turret'

wall_chests = ob.extend_walls(wall_chests, {loot = {callback = loot_callback}})
turret =
    ob.extend_walls(
    turret,
    {
        fallback = wall_chests,
        max_count = 2,
        turret = {callback = ob.refill_turret_callback, data = ob.piercing_rounds_magazine_ammo}
    }
)

local blank = require 'map_gen.presets.crash_site.outpost_data.mini_blank'
local base_factory = require 'map_gen.presets.crash_site.outpost_data.mini_factory'
local gun_turret_block = require 'map_gen.presets.crash_site.outpost_data.mini_gun_turret_block'

local factory = ob.extend_1_way(base_factory, {factory = {callback = factory_callback}, fallback = blank})
local gun =
    ob.extend_1_way(
    gun_turret_block,
    {fallback = factory, turret = {callback = ob.refill_turret_callback, data = ob.piercing_rounds_magazine_ammo}}
)

return {
    settings = {
        part_size = 3,
        blocks = 4,
        variance = 3,
        min_step = 1,
        max_level = 2
    },
    walls = {
        turret,
        wall_chests
    },
    bases = {{factory, gun}}
}
