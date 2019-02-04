local ob = require 'map_gen.maps.crash_site.outpost_builder'
local Token = require 'utils.token'

local loot = {
    {weight = 10},
    {stack = {name = 'coin', count = 50, distance_factor = 1 / 20}, weight = 5},
    {stack = {name = 'iron-plate', count = 500, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'steel-plate', count = 100, distance_factor = 1 / 5}, weight = 1},
    {stack = {name = 'iron-gear-wheel', count = 1000, distance_factor = 1}, weight = 5},
    {stack = {name = 'pipe', count = 200, distance_factor = 1}, weight = 1},
    {stack = {name = 'engine-unit', count = 100, distance_factor = 1 / 2}, weight = 10},
    {stack = {name = 'electric-engine-unit', count = 50, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'car', count = 1, distance_factor = 1 / 128}, weight = 2},
    {stack = {name = 'rail', count = 100, distance_factor = 1}, weight = 2}
}

local weights = ob.prepare_weighted_loot(loot)

local loot_callback =
    Token.register(
    function(chest)
        ob.do_random_loot(chest, weights, loot)
    end
)

local factory = {
    callback = ob.magic_item_crafting_callback,
    data = {
        recipe = 'iron-gear-wheel',
        output = {min_rate = 0.75 / 60, distance_factor = 0.75 / 60 / 512, item = 'iron-gear-wheel'}
    }
}

local factory_b = {
    callback = ob.magic_item_crafting_callback,
    data = {
        recipe = 'engine-unit',
        output = {min_rate = 0.25 / 60, distance_factor = 0.25 / 60 / 512, item = 'engine-unit'}
    }
}

local market = {
    callback = ob.market_set_items_callback,
    data = {
        market_name = 'Small Gear Factory',
        upgrade_rate = 0.5,
        upgrade_base_cost = 200,
        upgrade_cost_base = 2,
        {
            name = 'iron-gear-wheel',
            price = 0.5,
            distance_factor = 0.25 / 512,
            min_price = 0.05
        },
        {
            name = 'iron-plate',
            price = 0.4,
            distance_factor = 0.2 / 512,
            min_price = 0.04
        },
        {
            name = 'steel-plate',
            price = 2,
            distance_factor = 1 / 512,
            min_price = 0.2
        },
        {
            name = 'engine-unit',
            price = 4,
            distance_factor = 2 / 512,
            min_price = 0.4
        },
        {
            name = 'electric-engine-unit',
            price = 8,
            distance_factor = 4 / 512,
            min_price = 0.8
        },
        {
            name = 'car',
            price = 50,
            distance_factor = 25 / 512,
            min_price = 40
        },
        {
            name = 'rail',
            price = 1,
            distance_factor = 0.5 / 512,
            min_price = 0.1
        }
    }
}

local turrets = require 'map_gen.maps.crash_site.outpost_data.light_gun_turrets'
local worms = require 'map_gen.maps.crash_site.outpost_data.big_worm_turrets'
worms = ob.extend_walls(worms, {max_count = 2, fallback = turrets})

local base_factory = require 'map_gen.maps.crash_site.outpost_data.small_factory'

local level2 = ob.extend_1_way(base_factory[1], {loot = {callback = loot_callback}})
local level3 =
    ob.extend_1_way(
    base_factory[2],
    {
        factory = factory,
        fallback = level2
    }
)
local level3b =
    ob.extend_1_way(
    base_factory[2],
    {
        factory = factory_b,
        fallback = level3,
        max_count = 1
    }
)
local level4 =
    ob.extend_1_way(
    base_factory[3],
    {
        market = market,
        fallback = level3b
    }
)
return {
    settings = {
        blocks = 6,
        variance = 3,
        min_step = 2,
        max_level = 2
    },
    walls = {
        worms
    },
    bases = {
        {level4, level2}
    }
}
