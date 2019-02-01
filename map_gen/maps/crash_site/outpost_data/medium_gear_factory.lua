local ob = require 'map_gen.maps.crash_site.outpost_builder'
local Token = require 'utils.token'

local loot = {
    {weight = 5},
    {stack = {name = 'coin', count = 75, distance_factor = 1 / 20}, weight = 5},
    {stack = {name = 'iron-plate', count = 1000, distance_factor = 1}, weight = 5},
    {stack = {name = 'steel-plate', count = 500, distance_factor = 1 / 2}, weight = 1},
    {stack = {name = 'iron-gear-wheel', count = 1500, distance_factor = 1}, weight = 10},
    {stack = {name = 'engine-unit', count = 200, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'electric-engine-unit', count = 100, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'rail', count = 500, distance_factor = 1}, weight = 2},
    {stack = {name = 'tank', count = 1, distance_factor = 1 / 128}, weight = 2},
    {stack = {name = 'locomotive', count = 5, distance_factor = 1 / 128}, weight = 2},
    {stack = {name = 'cargo-wagon', count = 5, distance_factor = 1 / 128}, weight = 2},
    {stack = {name = 'fluid-wagon', count = 5, distance_factor = 1 / 128}, weight = 2}
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
        output = {min_rate = 3 / 60, distance_factor = 3 / 60 / 512, item = 'iron-gear-wheel'}
    }
}

local factory_b = {
    callback = ob.magic_item_crafting_callback,
    data = {
        recipe = 'engine-unit',
        output = {min_rate = 0.5 / 60, distance_factor = 0.5 / 60 / 512, item = 'engine-unit'}
    }
}

local factory_c = {
    callback = ob.magic_item_crafting_callback,
    data = {
        recipe = 'electric-engine-unit',
        output = {min_rate = 0.5 / 60, distance_factor = 0.5 / 60 / 512, item = 'electric-engine-unit'}
    }
}

local market = {
    callback = ob.market_set_items_callback,
    data = {
        market_name = 'Medium Gear Factory',
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
            name = 'tank',
            price = 500,
            distance_factor = 250 / 512,
            min_price = 50
        },
        {
            name = 'locomotive',
            price = 100,
            distance_factor = 50 / 512,
            min_price = 40
        },
        {
            name = 'cargo-wagon',
            price = 20,
            distance_factor = 10 / 512,
            min_price = 10
        },
        {
            name = 'fluid-wagon',
            price = 40,
            distance_factor = 20 / 512,
            min_price = 20
        },
        {
            name = 'rail',
            price = 1,
            distance_factor = 0.5 / 512,
            min_price = 0.1
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
        fallback = level2,
        max_count = 2
    }
)

local level3c =
    ob.extend_1_way(
    base_factory[2],
    {
        factory = factory_c,
        fallback = level3b,
        max_count = 2
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
        blocks = 7,
        variance = 3,
        min_step = 2,
        max_level = 2
    },
    walls = {
        require 'map_gen.maps.crash_site.outpost_data.medium_gun_turrets'
    },
    bases = {
        {level4, level3, level2}
    }
}
