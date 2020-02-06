local ob = require 'map_gen.maps.crash_site.outpost_builder'
local Token = require 'utils.token'

local loot = {
    {weight = 10},
    {stack = {name = 'coin', count = 250, distance_factor = 1 / 20}, weight = 5},
    {stack = {name = 'uranium-238', count = 500, distance_factor = 1 / 4}, weight = 5},
    {stack = {name = 'uranium-235', count = 20, distance_factor = 1 / 128}, weight = 2},
    {stack = {name = 'uranium-fuel-cell', count = 50, distance_factor = 1 / 128}, weight = 5},
    {stack = {name = 'nuclear-fuel', count = 10, distance_factor = 1 / 128}, weight = 3},
    {stack = {name = 'nuclear-reactor', count = 2, distance_factor = 1 / 512}, weight = 5},
    {stack = {name = 'heat-exchanger', count = 16, distance_factor = 1 / 64}, weight = 5},
    {stack = {name = 'heat-pipe', count = 50, distance_factor = 1 / 64}, weight = 5},
    {stack = {name = 'steam-turbine', count = 25, distance_factor = 1 / 64}, weight = 5},
    {stack = {name = 'medium-electric-pole', count = 50, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'big-electric-pole', count = 50, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'substation', count = 50, distance_factor = 1 / 2}, weight = 5}
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
        recipe = 'uranium-processing',
        output = {min_rate = 0.5 / 60, distance_factor = 0.5 / 60 / 512, item = 'uranium-238'}
    }
}

local factory_b = {
    callback = ob.magic_item_crafting_callback,
    data = {
        recipe = 'uranium-fuel-cell',
        output = {min_rate = 0.025 / 60, distance_factor = 0.025 / 60 / 512, item = 'uranium-fuel-cell'}
    }
}

local factory_c = {
    callback = ob.magic_item_crafting_callback,
    data = {
        recipe = 'nuclear-fuel',
        output = {min_rate = 0.025 / 60, distance_factor = 0.025 / 60 / 512, item = 'nuclear-fuel'}
    }
}

local market = {
    callback = ob.market_set_items_callback,
    data = {
        market_name = 'Big Power Factory',
        upgrade_rate = 0.5,
        upgrade_base_cost = 350,
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
            name = 'uranium-fuel-cell',
            price = 5,
            distance_factor = 2.5 / 512,
            min_price = 0.5
        },
        {
            name = 'nuclear-fuel',
            price = 10,
            distance_factor = 5 / 512,
            min_price = 0.1
        },
        {
            name = 'uranium-238',
            price = 1,
            distance_factor = 0.5 / 512,
            min_price = 0.1
        },
        {
            name = 'uranium-235',
            price = 99,
            distance_factor = 49.5 / 512,
            min_price = 9.9
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
            name = 'nuclear-reactor',
            price = 500,
            distance_factor = 250 / 512,
            min_price = 50
        },
        {
            name = 'heat-exchanger',
            price = 30,
            distance_factor = 15 / 512,
            min_price = 3
        },
        {
            name = 'heat-pipe',
            price = 3,
            distance_factor = 1.5 / 512,
            min_price = 0.3
        },
        {
            name = 'steam-turbine',
            price = 30,
            distance_factor = 15 / 512,
            min_price = 3
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

local base_factory = require 'map_gen.maps.crash_site.outpost_data.big_factory'
local base_factory2 = require 'map_gen.maps.crash_site.outpost_data.big_centrifuge'

local level2 = ob.extend_1_way(base_factory[1], {loot = {callback = loot_callback}})
local level3 =
    ob.extend_1_way(
    base_factory2[2],
    {
        factory = factory,
        fallback = level2,
        max_count = 4
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

local level3c =
    ob.extend_1_way(
    base_factory2[2],
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
        blocks = 9,
        variance = 3,
        min_step = 2,
        max_level = 2
    },
    walls = {
        require 'map_gen.maps.crash_site.outpost_data.heavy_gun_turrets'
    },
    bases = {
        {level4, level2}
    }
}
