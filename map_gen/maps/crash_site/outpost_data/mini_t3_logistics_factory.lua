local ob = require 'map_gen.maps.crash_site.outpost_builder'
local Token = require 'utils.token'

local loot = {
    {weight = 10},
    {stack = {name = 'coin', count = 200, distance_factor = 1 / 8}, weight = 5},
    {stack = {name = 'express-transport-belt', count = 100, distance_factor = 1 / 8}, weight = 5},
    {stack = {name = 'express-underground-belt', count = 20, distance_factor = 1 / 16}, weight = 5},
    {stack = {name = 'express-splitter', count = 10, distance_factor = 1 / 32}, weight = 5},
    {stack = {name = 'stack-inserter', count = 50, distance_factor = 1 / 32}, weight = 5},
    {stack = {name = 'assembling-machine-3', count = 25, distance_factor = 1 / 32}, weight = 2}
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
            recipe = 'express-transport-belt',
            output = {item = 'express-transport-belt', min_rate = 1 / 2 / 60, distance_factor = 1 / 2 / 60 / 512}
        },
        weight = 5
    },
    {
        stack = {
            recipe = 'express-underground-belt',
            output = {item = 'express-underground-belt', min_rate = 1 / 8 / 60, distance_factor = 1 / 8 / 60 / 512}
        },
        weight = 5
    },
    {
        stack = {
            recipe = 'express-splitter',
            output = {item = 'express-splitter', min_rate = 1 / 8 / 60, distance_factor = 1 / 8 / 60 / 512}
        },
        weight = 5
    },
    {
        stack = {
            recipe = 'stack-inserter',
            output = {item = 'stack-inserter', min_rate = 1 / 2 / 60, distance_factor = 1 / 2 / 60 / 512}
        },
        weight = 5
    },
    {
        stack = {
            recipe = 'assembling-machine-3',
            output = {item = 'assembling-machine-3', min_rate = 1 / 4 / 60, distance_factor = 1 / 4 / 60 / 512}
        },
        weight = 5
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
        turret = {callback = ob.refill_turret_callback, data = ob.uranium_rounds_magazine_ammo}
    }
)

local blank = require 'map_gen.maps.crash_site.outpost_data.mini_blank'
local base_factory = require 'map_gen.maps.crash_site.outpost_data.mini_factory'
local gun_turret_block = require 'map_gen.maps.crash_site.outpost_data.mini_gun_turret_block'

local factory = ob.extend_1_way(base_factory, {factory = factory_callback, fallback = blank})
local gun =
    ob.extend_1_way(
    gun_turret_block,
    {fallback = factory, turret = {callback = ob.refill_turret_callback, data = ob.uranium_rounds_magazine_ammo}}
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
