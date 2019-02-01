local ob = require 'map_gen.maps.crash_site.outpost_builder'
local Token = require 'utils.token'

local loot = {
    {weight = 10},
    {stack = {name = 'coin', count = 250, distance_factor = 1 / 20}, weight = 5},
    {stack = {name = 'solid-fuel', count = 1000, distance_factor = 1}, weight = 2},
    {stack = {name = 'sulfur', count = 1000, distance_factor = 1 / 2}, weight = 1},
    {stack = {name = 'plastic-bar', count = 1000, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'battery', count = 1200, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'explosives', count = 800, distance_factor = 1 / 2}, weight = 2},
    {stack = {name = 'rocket-fuel', count = 30, distance_factor = 1 / 20}, weight = 1},
    {stack = {name = 'poison-capsule', count = 500, distance_factor = 1 / 4}, weight = 2},
    {stack = {name = 'slowdown-capsule', count = 500, distance_factor = 1 / 4}, weight = 1}
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
        recipe = 'plastic-bar',
        output = {min_rate = 1.25 / 60, distance_factor = 1 / 60 / 512, item = 'plastic-bar'}
    }
}

local factory_b = {
    callback = ob.magic_item_crafting_callback,
    data = {
        recipe = 'sulfuric-acid',
        output = {min_rate = 10 / 60, distance_factor = 10 / 60 / 512, item = 'sulfuric-acid', fluidbox_index = 2}
    }
}
local factory_c = {
    callback = ob.magic_item_crafting_callback,
    data = {
        recipe = 'rocket-fuel',
        output = {min_rate = 0.5 / 60, distance_factor = 0.5 / 60 / 512, item = 'rocket-fuel'}
    }
}

local market = {
    callback = ob.market_set_items_callback,
    data = {
        market_name = 'Big Chemical Factory',
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
            name = 'rocket-fuel',
            price = 10,
            distance_factor = 5 / 512,
            min_price = 1
        },
        {
            name = 'poison-capsule',
            price = 15,
            distance_factor = 7.5 / 512,
            min_price = 1.5
        },
        {
            name = 'slowdown-capsule',
            price = 15,
            distance_factor = 7.5 / 512,
            min_price = 1.5
        }
    }
}

local base_factory = require 'map_gen.maps.crash_site.outpost_data.big_chemical_plant'
local base_factory2 = require 'map_gen.maps.crash_site.outpost_data.big_factory'

local level2 = ob.extend_1_way(base_factory[1], {loot = {callback = loot_callback}})
local level3 =
    ob.extend_1_way(
    base_factory[2],
    {
        factory = factory,
        fallback = level2,
        max_count = 6
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

local level3c =
    ob.extend_1_way(
    base_factory2[2],
    {
        factory = factory_c,
        fallback = level3b,
        max_count = 1
    }
)
local level4 =
    ob.extend_1_way(
    base_factory[3],
    {
        market = market,
        fallback = level3c
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
        require 'map_gen.maps.crash_site.outpost_data.heavy_flame_turrets'
    },
    bases = {
        {level3b, level2},
        {level4}
    }
}
