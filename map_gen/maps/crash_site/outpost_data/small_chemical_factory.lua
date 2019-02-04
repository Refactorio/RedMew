local ob = require 'map_gen.maps.crash_site.outpost_builder'
local Token = require 'utils.token'

local loot = {
    {weight = 10},
    {stack = {name = 'coin', count = 50, distance_factor = 1 / 20}, weight = 5},
    {stack = {name = 'coal', count = 1000, distance_factor = 1}, weight = 2},
    {stack = {name = 'sulfur', count = 500, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'plastic-bar', count = 500, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'poison-capsule', count = 50, distance_factor = 1 / 32}, weight = 2},
    {stack = {name = 'slowdown-capsule', count = 50, distance_factor = 1 / 32}, weight = 1}
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
        recipe = 'sulfur',
        output = {min_rate = 1 / 60, distance_factor = 1 / 60 / 512, item = 'sulfur'}
    }
}

local factory_b = {
    callback = ob.magic_item_crafting_callback,
    data = {
        recipe = 'plastic-bar',
        output = {min_rate = 1 / 60, distance_factor = 1 / 60 / 512, item = 'plastic-bar'}
    }
}

local market = {
    callback = ob.market_set_items_callback,
    data = {
        market_name = 'Small Chemical Factory',
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

local base_factory = require 'map_gen.maps.crash_site.outpost_data.small_chemical_plant'

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
        blocks = 6,
        variance = 3,
        min_step = 2,
        max_level = 2
    },
    walls = {
        require 'map_gen.maps.crash_site.outpost_data.light_flame_turrets'
    },
    bases = {
        {level4, level3, level2}
    }
}
