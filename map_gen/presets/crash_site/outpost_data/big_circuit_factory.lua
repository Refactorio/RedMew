local ob = require 'map_gen.presets.crash_site.outpost_builder'

local Token = require 'utils.global_token'

local loot = {
    {weight = 10},
    {stack = {name = 'coin', count = 2500, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'copper-cable', count = 300, distance_factor = 3 / 4}, weight = 5},
    {stack = {name = 'electronic-circuit', count = 800, distance_factor = 1}, weight = 5},
    {stack = {name = 'advanced-circuit', count = 400, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'processing-unit', count = 200, distance_factor = 1 / 4}, weight = 5}
}

local factory = {
    callback = ob.magic_item_crafting_callback,
    data = {
        recipe = 'electronic-circuit',
        output = {min_rate = 1 / 60, distance_factor = 1 / 60 / 100, item = 'electronic-circuit'}
    }
}

local factory_b = {
    callback = ob.magic_item_crafting_callback,
    data = {
        recipe = 'advanced-circuit',
        output = {min_rate = 1 / 60, distance_factor = 1 / 60 / 100, item = 'advanced-circuit'}
    }
}

local factory_c = {
    callback = ob.magic_item_crafting_callback,
    data = {
        recipe = 'processing-unit',
        output = {min_rate = 1 / 600, distance_factor = 1 / 600 / 100, item = 'processing-unit'}
    }
}

local market = {
    callback = ob.market_set_items_callback,
    data = {
        {
            name = 'copper-cable',
            price = 0.25,
            distance_factor = 0.005 / 32,
            min_price = 0.025
        },
        {
            name = 'electronic-circuit',
            price = 1,
            distance_factor = 0.005 / 32,
            min_price = 0.05
        },
        {
            name = 'advanced-circuit',
            price = 4,
            distance_factor = 0.005 / 32,
            min_price = 0.2
        },
        {
            name = 'processing-unit',
            price = 16,
            distance_factor = 0.005 / 32,
            min_price = 0.8
        }
    }
}

local weights = ob.prepare_weighted_loot(loot)

local loot_callback =
    Token.register(
    function(chest)
        ob.do_random_loot(chest, weights, loot)
    end
)

local base_factory = require 'map_gen.presets.crash_site.outpost_data.big_factory'

local level2 = ob.extend_1_way(base_factory[1], {loot = {callback = loot_callback}})
local level3 =
    ob.extend_1_way(
    base_factory[2],
    {
        factory = factory,
        fallback = level2
    }
)
local level3_b =
    ob.extend_1_way(
    base_factory[2],
    {
        factory = factory_b,
        fallback = level3
    }
)
local level3_c =
    ob.extend_1_way(
    base_factory[2],
    {
        factory = factory_c,
        fallback = level3_b
    }
)
local level4 =
    ob.extend_1_way(
    base_factory[3],
    {
        market = market,
        fallback = level3_c
    }
)

return {
    settings = {
        blocks = 9,
        variance = 3,
        min_step = 2,
        max_level = 2
    },
    walls = {
        require 'map_gen.presets.crash_site.outpost_data.heavy_laser_turrets'
    },
    bases = {
        {level4, level2}
    }
}
