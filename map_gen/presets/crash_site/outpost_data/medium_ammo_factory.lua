local ob = require 'map_gen.presets.crash_site.outpost_builder'
local Token = require 'utils.global_token'

local loot = {
    {weight = 10},
    {stack = {name = 'coin', count = 750, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'piercing-rounds-magazine', count = 500, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'uranium-rounds-magazine', count = 300, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'piercing-shotgun-shell', count = 200, distance_factor = 1 / 4}, weight = 2},
    {stack = {name = 'grenade', count = 100, distance_factor = 1 / 8}, weight = 1},
    {stack = {name = 'land-mine', count = 400, distance_factor = 1}, weight = 1},
    {stack = {name = 'rocket', count = 200, distance_factor = 1 / 32}, weight = 2},
    {stack = {name = 'explosive-rocket', count = 200, distance_factor = 1 / 32}, weight = 1},
    {stack = {name = 'cannon-shell', count = 200, distance_factor = 1 / 32}, weight = 2},
    {stack = {name = 'explosive-cannon-shell', count = 200, distance_factor = 1 / 32}, weight = 1},
    {stack = {name = 'cluster-grenade', count = 100, distance_factor = 1 / 32}, weight = 1},
    {stack = {name = 'poison-capsule', count = 100, distance_factor = 1 / 32}, weight = 1},
    {stack = {name = 'slowdown-capsule', count = 100, distance_factor = 1 / 32}, weight = 1},
    {stack = {name = 'destroyer-capsule', count = 20, distance_factor = 1 / 32}, weight = 1}
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
        output = {min_rate = 1 / 60, distance_factor = 1 / 60 / 100, item = 'piercing-rounds-magazine'}
    }
}

local factory_b = {
    callback = ob.magic_item_crafting_callback,
    data = {
        recipe = 'cannon-shell',
        output = {min_rate = 1 / 3 / 60, distance_factor = 1 / 60 / 100, item = 'cannon-shell'}
    }
}

local factory_c = {
    callback = ob.magic_item_crafting_callback,
    data = {
        recipe = 'uranium-rounds-magazine',
        output = {min_rate = 1 / 3 / 60, distance_factor = 1 / 60 / 100, item = 'uranium-rounds-magazine'}
    }
}

local market = {
    callback = ob.market_set_items_callback,
    data = {
        {
            name = 'firearm-magazine',
            price = 1,
            distance_factor = 0.005 / 32,
            min_price = 0.1
        },
        {
            name = 'piercing-rounds-magazine',
            price = 3,
            distance_factor = 0.005 / 32,
            min_price = 0.3
        },
        {
            name = 'uranium-rounds-magazine',
            price = 9,
            distance_factor = 0.005 / 32,
            min_price = 0.9
        },
        {
            name = 'shotgun-shell',
            price = 2,
            distance_factor = 0.005 / 32,
            min_price = 0.2
        },
        {
            name = 'piercing-shotgun-shell',
            price = 6,
            distance_factor = 0.005 / 32,
            min_price = 0.6
        },
        {
            name = 'grenade',
            price = 10,
            distance_factor = 0.005 / 32,
            min_price = 1
        },
        {
            name = 'land-mine',
            price = 1,
            distance_factor = 0.005 / 32,
            min_price = 0.1
        },
        {
            name = 'rocket',
            price = 20,
            distance_factor = 0.005 / 32,
            min_price = 2
        },
        {
            name = 'explosive-rocket',
            price = 40,
            distance_factor = 0.005 / 32,
            min_price = 4
        },
        {
            name = 'rocket-launcher',
            price = 250,
            distance_factor = 0.005 / 32,
            min_price = 125
        },
        {
            name = 'cluster-grenade',
            price = 100,
            distance_factor = 0.005 / 32,
            min_price = 10
        },
        {
            name = 'poison-capsule',
            price = 60,
            distance_factor = 0.005 / 32,
            min_price = 6
        },
        {
            name = 'slowdown-capsule',
            price = 60,
            distance_factor = 0.005 / 32,
            min_price = 6
        },
        {
            name = 'cannon-shell',
            price = 60,
            distance_factor = 0.005 / 32,
            min_price = 6
        },
        {
            name = 'explosive-cannon-shell',
            price = 120,
            distance_factor = 0.005 / 32,
            min_price = 12
        },
        {
            name = 'destroyer-capsule',
            price = 80,
            distance_factor = 0.005 / 32,
            min_price = 8
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
        fallback = level3,
        max_count = 2
    }
)
local level3c =
    ob.extend_1_way(
    base_factory[2],
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
        blocks = 8,
        variance = 3,
        min_step = 2,
        max_level = 2
    },
    walls = {
        require 'map_gen.presets.crash_site.outpost_data.heavy_gun_turrets',
        require 'map_gen.presets.crash_site.outpost_data.heavy_laser_turrets',
        require 'map_gen.presets.crash_site.outpost_data.heavy_flame_turrets'
    },
    bases = {
        {level4, level2}
    }
}
