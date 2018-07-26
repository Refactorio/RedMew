local ob = require 'map_gen.presets.crash_site.outpost_builder'
local Token = require 'utils.global_token'

local loot = {
    {weight = 10},
    {stack = {name = 'coin', count = 2500, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'science-pack-1', count = 200, distance_factor = 1 / 10}, weight = 2},
    {stack = {name = 'science-pack-2', count = 100, distance_factor = 1 / 10}, weight = 2},
    {stack = {name = 'military-science-pack', count = 75, distance_factor = 1 / 10}, weight = 3},
    {stack = {name = 'science-pack-3', count = 75, distance_factor = 1 / 10}, weight = 3},
    {stack = {name = 'production-science-pack', count = 50, distance_factor = 1 / 10}, weight = 5},
    {stack = {name = 'high-tech-science-pack', count = 50, distance_factor = 1 / 10}, weight = 5}
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
        recipe = 'production-science-pack',
        output = {min_rate = 0.1 / 60, distance_factor = 1 / 60 / 1000, item = 'production-science-pack'}
    }
}

local factory_b = {
    callback = ob.magic_item_crafting_callback,
    data = {
        recipe = 'high-tech-science-pack',
        output = {min_rate = 0.1 / 60, distance_factor = 1 / 60 / 1000, item = 'high-tech-science-pack'}
    }
}

local market = {
    callback = ob.market_set_items_callback,
    data = {
        {
            name = 'science-pack-1',
            price = 10,
            distance_factor = 0.005 / 32,
            min_price = 1
        },
        {
            name = 'science-pack-2',
            price = 20,
            distance_factor = 0.005 / 32,
            min_price = 2
        },
        {
            name = 'military-science-pack',
            price = 40,
            distance_factor = 0.005 / 32,
            min_price = 4
        },
        {
            name = 'science-pack-3',
            price = 60,
            distance_factor = 0.005 / 32,
            min_price = 4
        },
        {
            name = 'production-science-pack',
            price = 120,
            distance_factor = 0.005 / 32,
            min_price = 4
        },
        {
            name = 'high-tech-science-pack',
            price = 180,
            distance_factor = 0.005 / 32,
            min_price = 4
        }
    }
}

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
local level3b =
    ob.extend_1_way(
    base_factory[2],
    {
        factory = factory_b,
        fallback = level2
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
        blocks = 9,
        variance = 3,
        min_step = 2,
        max_level = 3
    },
    walls = {
        require 'map_gen.presets.crash_site.outpost_data.heavy_laser_turrets'
    },
    bases = {
        {level3, level2},
        {level4}
    }
}
