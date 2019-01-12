local ob = require 'map_gen.presets.crash_site.outpost_builder'
local Token = require 'utils.token'

local loot = {
    {weight = 10},
    {stack = {name = 'coin', count = 75, distance_factor = 1 / 20}, weight = 5},
    {stack = {name = 'science-pack-1', count = 100, distance_factor = 1 / 10}, weight = 5},
    {stack = {name = 'science-pack-2', count = 50, distance_factor = 1 / 10}, weight = 5},
    {stack = {name = 'military-science-pack', count = 25, distance_factor = 1 / 10}, weight = 5},
    {stack = {name = 'science-pack-3', count = 25, distance_factor = 1 / 10}, weight = 5}
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
        recipe = 'military-science-pack',
        output = {min_rate = 0.15 / 60, distance_factor = 0.125 / 60 / 512, item = 'military-science-pack'}
    }
}

local factory_b = {
    callback = ob.magic_item_crafting_callback,
    data = {
        recipe = 'science-pack-3',
        output = {min_rate = 0.25 / 60, distance_factor = 0.15 / 60 / 512, item = 'science-pack-3'}
    }
}

local market = {
    callback = ob.market_set_items_callback,
    data = {
        market_name = 'Medium Science Factory',
        {
            name = 'science-pack-1',
            price = 10,
            distance_factor = 5 / 512,
            min_price = 1
        },
        {
            name = 'science-pack-2',
            price = 20,
            distance_factor = 10 / 512,
            min_price = 2
        },
        {
            name = 'military-science-pack',
            price = 40,
            distance_factor = 20 / 512,
            min_price = 4
        },
        {
            name = 'science-pack-3',
            price = 60,
            distance_factor = 30 / 512,
            min_price = 6
        }
    }
}

local base_factory = require 'map_gen.presets.crash_site.outpost_data.medium_factory'

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
        fallback = level3
    }
)
return {
    settings = {
        blocks = 7,
        variance = 3,
        min_step = 2,
        max_level = 2
    },
    walls = {
        require 'map_gen.presets.crash_site.outpost_data.medium_laser_turrets'
    },
    bases = {
        {level4, level3b, level2}
    }
}
