local ob = require 'map_gen.maps.crash_site.outpost_builder'
local Token = require 'utils.token'

local loot = {
    {weight = 10},
    {stack = {name = 'coin', count = 50, distance_factor = 1 / 20}, weight = 5},
    {stack = {name = 'coal', count = 1000, distance_factor = 1}, weight = 5},
    {stack = {name = 'solid-fuel', count = 500, distance_factor = 1}, weight = 5},
    {stack = {name = 'boiler', count = 25, distance_factor = 1 / 64}, weight = 5},
    {stack = {name = 'steam-engine', count = 50, distance_factor = 1 / 32}, weight = 5},
    {stack = {name = 'offshore-pump', count = 5, distance_factor = 1 / 128}, weight = 5},
    {stack = {name = 'pipe', count = 200, distance_factor = 1}, weight = 5},
    {stack = {name = 'pipe-to-ground', count = 50, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'medium-electric-pole', count = 50, distance_factor = 1 / 4}, weight = 5}
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
        output = {min_rate = 1 / 60, distance_factor = 1 / 60 / 512, item = 'coal'}
    }
}

local factory_b = {
    callback = ob.magic_item_crafting_callback,
    data = {
        recipe = 'solid-fuel-from-light-oil',
        output = {min_rate = 0.5 / 60, distance_factor = 0.5 / 60 / 512, item = 'solid-fuel'}
    }
}

local market = {
    callback = ob.market_set_items_callback,
    data = {
        market_name = 'Small Power Factory',
        upgrade_rate = 0.5,
        upgrade_base_cost = 200,
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
        }
    }
}

local turrets = require 'map_gen.maps.crash_site.outpost_data.light_gun_turrets'
local worms = require 'map_gen.maps.crash_site.outpost_data.big_worm_turrets'
worms = ob.extend_walls(worms, {max_count = 2, fallback = turrets})

local base_factory = require 'map_gen.maps.crash_site.outpost_data.small_furance'
local base_factory2 = require 'map_gen.maps.crash_site.outpost_data.small_chemical_plant'

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
    base_factory2[2],
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
        worms
    },
    bases = {
        {level4, level2}
    }
}
