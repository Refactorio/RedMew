local ob = require 'map_gen.presets.crash_site.outpost_builder'
local Token = require 'utils.global_token'

local loot = {
    {weight = 10},
    {stack = {name = 'coin', count = 250, distance_factor = 1 / 20}, weight = 5},
    {stack = {name = 'uranium-rounds-magazine', count = 600, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'piercing-shotgun-shell', count = 600, distance_factor = 1 / 4}, weight = 1},
    {stack = {name = 'cluster-grenade', count = 200, distance_factor = 1 / 8}, weight = 2},
    {stack = {name = 'explosive-rocket', count = 200, distance_factor = 1 / 8}, weight = 5},
    {stack = {name = 'explosive-cannon-shell', count = 200, distance_factor = 1 / 8}, weight = 5},
    {stack = {name = 'explosive-uranium-cannon-shell', count = 200, distance_factor = 1 / 8}, weight = 2},
    {stack = {name = 'destroyer-capsule', count = 100, distance_factor = 1 / 16}, weight = 2}
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
        recipe = 'uranium-rounds-magazine',
        output = {min_rate = 1 / 60, distance_factor = 1 / 60 / 512, item = 'uranium-rounds-magazine'}
    }
}

local factory_b = {
    callback = ob.magic_item_crafting_callback,
    data = {
        recipe = 'explosive-rocket',
        output = {min_rate = 1 / 3 / 60, distance_factor = 1 / 3 / 60 / 512, item = 'explosive-rocket'}
    }
}

local factory_c = {
    callback = ob.magic_item_crafting_callback,
    data = {
        recipe = 'explosive-uranium-cannon-shell',
        output = {min_rate = 1 / 3 / 60, distance_factor = 1 / 3 / 60 / 512, item = 'explosive-uranium-cannon-shell'}
    }
}

local market = {
    callback = ob.market_set_items_callback,
    data = {
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
            name = 'shotgun-shell',
            price = 2,
            distance_factor = 1 / 512,
            min_price = 0.2
        },
        {
            name = 'piercing-shotgun-shell',
            price = 6,
            distance_factor = 3 / 512,
            min_price = 0.6
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
            name = 'rocket',
            price = 20,
            distance_factor = 10 / 512,
            min_price = 2
        },
        {
            name = 'explosive-rocket',
            price = 40,
            distance_factor = 20 / 512,
            min_price = 4
        },
        {
            name = 'rocket-launcher',
            price = 250,
            distance_factor = 125 / 512,
            min_price = 125
        },
        {
            name = 'cluster-grenade',
            price = 100,
            distance_factor = 50 / 512,
            min_price = 10
        },
        {
            name = 'poison-capsule',
            price = 60,
            distance_factor = 30 / 512,
            min_price = 6
        },
        {
            name = 'slowdown-capsule',
            price = 60,
            distance_factor = 60 / 512,
            min_price = 6
        },
        {
            name = 'cannon-shell',
            price = 60,
            distance_factor = 60 / 512,
            min_price = 6
        },
        {
            name = 'explosive-cannon-shell',
            price = 120,
            distance_factor = 120 / 512,
            min_price = 12
        },
        {
            name = 'explosive-uranium-cannon-shell',
            price = 160,
            distance_factor = 80 / 512,
            min_price = 16
        },
        {
            name = 'destroyer-capsule',
            price = 80,
            distance_factor = 40 / 512,
            min_price = 8
        },
        {
            name = 'vehicle-machine-gun',
            price = 1000
        },
        {
            name = 'tank-cannon',
            price = 500
        },
        {
            name = 'artillery-wagon-cannon',
            price = 2000
        }
    }
}

local base_factory = require 'map_gen.presets.crash_site.outpost_data.big_factory'

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

local artillery =
    ob.extend_1_way(
    require 'map_gen.presets.crash_site.outpost_data.artillery_block',
    {fallback = level4, max_count = 1}
)

return {
    settings = {
        blocks = 11,
        variance = 3,
        min_step = 2,
        max_level = 5
    },
    walls = {
        require 'map_gen.presets.crash_site.outpost_data.heavy_gun_turrets',
        require 'map_gen.presets.crash_site.outpost_data.heavy_laser_turrets',
        require 'map_gen.presets.crash_site.outpost_data.heavy_flame_turrets'
    },
    bases = {
        {require 'map_gen.presets.crash_site.outpost_data.laser_block'},
        {level2},
        {level4},
        {artillery}
    }
}
