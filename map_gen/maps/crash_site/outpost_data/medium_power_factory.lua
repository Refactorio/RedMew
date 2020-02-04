local ob = require 'map_gen.maps.crash_site.outpost_builder'
local Token = require 'utils.token'

local loot = {
    {weight = 10},
    {stack = {name = 'coin', count = 75, distance_factor = 1 / 20}, weight = 5},
    {stack = {name = 'coal', count = 1000, distance_factor = 1}, weight = 5},
    {stack = {name = 'solid-fuel', count = 750, distance_factor = 1}, weight = 5},
    {stack = {name = 'battery', count = 500, distance_factor = 1}, weight = 5},
    {stack = {name = 'medium-electric-pole', count = 250, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'big-electric-pole', count = 50, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'substation', count = 50, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'solar-panel', count = 100, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'accumulator', count = 84, distance_factor = 1 / 2}, weight = 5}
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
        recipe = 'accumulator',
        output = {min_rate = 0.42 / 2 / 60, distance_factor = 0.42 / 2 / 60 / 512, item = 'accumulator'}
    }
}

local factory_b = {
    callback = ob.magic_item_crafting_callback,
    data = {
        recipe = 'solar-panel',
        output = {min_rate = 0.5 / 2 / 60, distance_factor = 0.5 / 2 / 60 / 512, item = 'solar-panel'}
    }
}

local market = {
    callback = ob.market_set_items_callback,
    data = {
        market_name = 'Medium Power Factory',
        upgrade_rate = 0.5,
        upgrade_base_cost = 250,
        upgrade_cost_base = 2,
        {
            name = 'coal',
            price = 0.5,
            distance_factor = 0.25 / 512,
            min_price = 0.05
        },
        {
            name = 'solid-fuel',
            price = 1.25,
            distance_factor = 0.75 / 512,
            min_price = 0.125
        },
        {
            name = 'boiler',
            price = 3,
            distance_factor = 1.5 / 512,
            min_price = 0.3
        },
        {
            name = 'steam-engine',
            price = 6,
            distance_factor = 3 / 512,
            min_price = 0.6
        },
        {
            name = 'solar-panel',
            price = 12,
            distance_factor = 6 / 512,
            min_price = 1.2
        },
        {
            name = 'accumulator',
            price = 4,
            distance_factor = 2 / 512,
            min_price = 0.4
        },
        {
            name = 'offshore-pump',
            price = 2,
            distance_factor = 1 / 512,
            min_price = 0.2
        },
        {
            name = 'pipe',
            price = 0.25,
            distance_factor = 0.125 / 512,
            min_price = 0.025
        },
        {
            name = 'pipe-to-ground',
            price = 2.5,
            distance_factor = 1.25 / 512,
            min_price = 0.25
        },
        {
            name = 'medium-electric-pole',
            price = 2,
            distance_factor = 1 / 512,
            min_price = 0.2
        },
        {
            name = 'big-electric-pole',
            price = 4,
            distance_factor = 2 / 512,
            min_price = 0.4
        },
        {
            name = 'substation',
            price = 8,
            distance_factor = 4 / 512,
            min_price = 0.8
        }
    }
}

local base_factory = require 'map_gen.maps.crash_site.outpost_data.medium_factory'

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

local level3b =
    ob.extend_1_way(
    base_factory[2],
    {
        factory = factory_b,
        fallback = level3,
        max_count = 2
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
        blocks = 7,
        variance = 3,
        min_step = 2,
        max_level = 2
    },
    walls = {
        require 'map_gen.maps.crash_site.outpost_data.medium_laser_turrets'
    },
    bases = {
        {level4, level2}
    }
}
