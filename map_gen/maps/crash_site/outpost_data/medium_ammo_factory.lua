local ob = require 'map_gen.maps.crash_site.outpost_builder'
local Token = require 'utils.token'

local loot = {
    {weight = 10},
    {stack = {name = 'coin', count = 150, distance_factor = 1 / 8}, weight = 5},
    {stack = {name = 'piercing-rounds-magazine', count = 500, distance_factor = 1}, weight = 5},
    {stack = {name = 'uranium-rounds-magazine', count = 100, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'grenade', count = 200, distance_factor = 1 / 8}, weight = 1},
    {stack = {name = 'land-mine', count = 400, distance_factor = 1}, weight = 1},
    {stack = {name = 'cannon-shell', count = 200, distance_factor = 1 / 32}, weight = 2},
    {stack = {name = 'explosive-cannon-shell', count = 200, distance_factor = 1 / 32}, weight = 1},
    {stack = {name = 'cluster-grenade', count = 100, distance_factor = 1 / 32}, weight = 1}
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
        recipe = 'piercing-rounds-magazine',
        output = {min_rate = 1 / 60, distance_factor = 1 / 60 / 512, item = 'piercing-rounds-magazine'}
    }
}

local factory_b = {
    callback = ob.magic_item_crafting_callback,
    data = {
        recipe = 'explosive-cannon-shell',
        output = {min_rate = 0.5 / 2 / 60, distance_factor = 0.5 / 2 / 60 / 512, item = 'explosive-cannon-shell'}
    }
}

local factory_c = {
    callback = ob.magic_item_crafting_callback,
    data = {
        recipe = 'uranium-rounds-magazine',
        output = {min_rate = 0.25 / 60, distance_factor = 0.25 / 60 / 512, item = 'uranium-rounds-magazine'}
    }
}

local market = {
    callback = ob.market_set_items_callback,
    data = {
        market_name = 'Medium Ammo Factory',
        upgrade_rate = 0.5,
        upgrade_base_cost = 500,
        upgrade_cost_base = 2,
        {
            name = 'firearm-magazine',
            price = 1,
            distance_factor = 0.5 / 512,
            min_price = 0.1
        },
        {
            name = 'piercing-rounds-magazine',
            price = 3,
            distance_factor = 1.5 / 512,
            min_price = 0.3
        },
        {
            name = 'uranium-rounds-magazine',
            price = 9,
            distance_factor = 4.5 / 512,
            min_price = 0.9
        },
        {
            name = 'grenade',
            price = 10,
            distance_factor = 5 / 512,
            min_price = 1
        },
        {
            name = 'land-mine',
            price = 1,
            distance_factor = 0.5 / 512,
            min_price = 0.1
        },
        {
            name = 'cluster-grenade',
            price = 100,
            distance_factor = 50 / 512,
            min_price = 10
        },
        {
            name = 'cannon-shell',
            price = 15,
            distance_factor = 7.5 / 512,
            min_price = 1.5
        },
        {
            name = 'explosive-cannon-shell',
            price = 30,
            distance_factor = 15 / 512,
            min_price = 3
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
        max_count = 5
    }
)
local level3b =
    ob.extend_1_way(
    base_factory[2],
    {
        factory = factory_b,
        fallback = level3,
        max_count = 1
    }
)
local level3c =
    ob.extend_1_way(
    base_factory[2],
    {
        factory = factory_c,
        fallback = level3,
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
        blocks = 8,
        variance = 3,
        min_step = 2,
        max_level = 2
    },
    walls = {
        require 'map_gen.maps.crash_site.outpost_data.heavy_gun_turrets',
        require 'map_gen.maps.crash_site.outpost_data.heavy_laser_turrets',
        require 'map_gen.maps.crash_site.outpost_data.heavy_flame_turrets'
    },
    bases = {
        {level4, level3b, level2}
    }
}
