local ob = require 'map_gen.presets.crash_site.outpost_builder'
local Token = require 'utils.global_token'

local loot = {
    {weight = 5},
    {stack = {name = 'coin', count = 50, distance_factor = 1 / 20}, weight = 5},
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
        recipe = 'engine-unit',
        output = {min_rate = 1 / 60, distance_factor = 1 / 60 / 512, item = 'engine-unit'}
    }
}

local market = {
    callback = ob.market_set_items_callback,
    data = {
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

local base_factory = require 'map_gen.presets.crash_site.outpost_data.small_factory'

local level2 = ob.extend_1_way(base_factory[1], {loot = {callback = loot_callback}})
local level3 =
    ob.extend_1_way(
    base_factory[2],
    {
        factory = factory,
        fallback = level2,
        max_count = 2
    }
)
local level4 =
    ob.extend_1_way(
    base_factory[3],
    {
        market = market,
        fallback = level3
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
        require 'map_gen.presets.crash_site.outpost_data.light_gun_turrets'
    },
    bases = {
        {level4, level2}
    }
}
