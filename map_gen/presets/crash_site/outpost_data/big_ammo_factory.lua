local ob = require 'map_gen.presets.crash_site.outpost_builder'
local Token = require 'utils.global_token'

local loot = {
    {weight = 10},
    {stack = {name = 'coin', count = 500, distance_factor = 1 / 8}, weight = 5},
    {stack = {name = 'uranium-rounds-magazine', count = 2000, distance_factor = 1}, weight = 5},
    {stack = {name = 'cluster-grenade', count = 200, distance_factor = 1 / 8}, weight = 2},
    {stack = {name = 'explosive-cannon-shell', count = 200, distance_factor = 1 / 8}, weight = 5},
    {stack = {name = 'explosive-uranium-cannon-shell', count = 200, distance_factor = 1 / 8}, weight = 2}
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
        output = {min_rate = 2 / 60, distance_factor = 2 / 60 / 512, item = 'uranium-rounds-magazine'}
    }
}

local factory_b = {
    callback = ob.magic_item_crafting_callback,
    data = {
        recipe = 'explosive-uranium-cannon-shell',
        output = {min_rate = 1 / 2 / 60, distance_factor = 1 / 2 / 60 / 512, item = 'explosive-uranium-cannon-shell'}
    }
}

local market = {
    callback = ob.market_set_items_callback,
    data = {
        {
            name = 'firearm-magazine',
            price = 0.5,
            distance_factor = 0.25 / 512,
            min_price = 0.1
        },
        {
            name = 'piercing-rounds-magazine',
            price = 1.5,
            distance_factor = 0.75 / 512,
            min_price = 0.15
        },
        {
            name = 'uranium-rounds-magazine',
            price = 4.5,
            distance_factor = 2.25 / 512,
            min_price = 0.45
        },
        {
            name = 'grenade',
            price = 5,
            distance_factor = 2.5 / 512,
            min_price = 0.5
        },
        {
            name = 'land-mine',
            price = 1,
            distance_factor = 0.5 / 512,
            min_price = 0.1
        },
        {
            name = 'cluster-grenade',
            price = 50,
            distance_factor = 25 / 512,
            min_price = 5
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
        },
        {
            name = 'explosive-uranium-cannon-shell',
            price = 60,
            distance_factor = 30 / 512,
            min_price = 6
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

local level4 =
    ob.extend_1_way(
    base_factory[3],
    {
        market = market,
        fallback = level3b
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
