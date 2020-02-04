local ob = require 'map_gen.maps.crash_site.outpost_builder'
local Token = require 'utils.token'

local loot = {
    {weight = 10},
    {stack = {name = 'coin', count = 75, distance_factor = 1 / 20}, weight = 5},
    {stack = {name = 'solid-fuel', count = 500, distance_factor = 1}, weight = 2},
    {stack = {name = 'sulfur', count = 500, distance_factor = 1 / 2}, weight = 3},
    {stack = {name = 'plastic-bar', count = 500, distance_factor = 1 / 2}, weight = 3},
    {stack = {name = 'battery', count = 600, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'explosives', count = 400, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'poison-capsule', count = 100, distance_factor = 1 / 16}, weight = 2},
    {stack = {name = 'slowdown-capsule', count = 100, distance_factor = 1 / 16}, weight = 1}
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
        recipe = 'battery',
        output = {min_rate = 0.75 / 60, distance_factor = 0.75 / 60 / 512, item = 'battery'}
    }
}

local factory_b = {
    callback = ob.magic_item_crafting_callback,
    data = {
        recipe = 'explosives',
        output = {min_rate = 1 / 60, distance_factor = 1 / 60 / 512, item = 'explosives'}
    }
}

local market = {
    callback = ob.market_set_items_callback,
    data = {
        market_name = 'Medium Checmical Factory',
        upgrade_rate = 0.5,
        upgrade_base_cost = 250,
        upgrade_cost_base = 2,
        {
            name = 'coal',
            price = 0.25,
            distance_factor = 0.125 / 512,
            min_price = 0.025
        },
        {
            name = 'sulfur',
            price = 2,
            distance_factor = 1 / 512,
            min_price = 0.2
        },
        {
            name = 'plastic-bar',
            price = 2,
            distance_factor = 1 / 512,
            min_price = 0.2
        },
        {
            name = 'solid-fuel',
            price = 1,
            distance_factor = 0.5 / 512,
            min_price = 0.1
        },
        {
            name = 'battery',
            price = 3,
            distance_factor = 1.5 / 512,
            min_price = 0.3
        },
        {
            name = 'explosives',
            price = 3,
            distance_factor = 1.5 / 512,
            min_price = 0.3
        },
        {
            name = 'poison-capsule',
            price = 30,
            distance_factor = 15 / 512,
            min_price = 3
        },
        {
            name = 'slowdown-capsule',
            price = 30,
            distance_factor = 15 / 512,
            min_price = 3
        },
    }
}

local base_factory = require 'map_gen.maps.crash_site.outpost_data.medium_chemical_plant'

local level2 = ob.extend_1_way(base_factory[1], {loot = {callback = loot_callback}})
local level3 =
    ob.extend_1_way(
    base_factory[2],
    {
        factory = factory,
        fallback = level2,
        max_count = 3
    }
)
local level3b =
    ob.extend_1_way(
    base_factory[2],
    {
        factory = factory_b,
        fallback = level3,
        max_count = 3
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
        require 'map_gen.maps.crash_site.outpost_data.medium_flame_turrets'
    },
    bases = {
        {level4, level3, level2}
    }
}
