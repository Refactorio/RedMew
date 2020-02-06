local ob = require 'map_gen.maps.crash_site.outpost_builder'
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
    {
        stack = {
            recipe = 'solar-panel',
            output = {item = 'solar-panel', min_rate = 0.25 / 4 / 60, distance_factor = 0.25 / 4 / 60 / 512}
        },
        weight = 3
    },
    {
        stack = {
            recipe = 'accumulator',
            output = {item = 'accumulator', min_rate = 0.21 / 4 / 60, distance_factor = 0.21 / 4 / 60 / 512}
        },
        weight = 3
    }
}

local factory_weights = ob.prepare_weighted_loot(factory_loot)

local factory_callback = {
    callback = ob.magic_item_crafting_callback_weighted,
    data = {
        loot = factory_loot,
        weights = factory_weights
    }
}

local wall_chests = require 'map_gen.maps.crash_site.outpost_data.mini_wall_chests'
local turret = require 'map_gen.maps.crash_site.outpost_data.mini_gun_turret'

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

local blank = require 'map_gen.maps.crash_site.outpost_data.mini_blank'
local base_factory = require 'map_gen.maps.crash_site.outpost_data.mini_factory'
local gun_turret_block = require 'map_gen.maps.crash_site.outpost_data.mini_gun_turret_block'

local factory = ob.extend_1_way(base_factory, {factory = factory_callback, fallback = blank})
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
