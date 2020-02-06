local ob = require 'map_gen.maps.crash_site.outpost_builder'
local Token = require 'utils.token'

local loot = {
    {weight = 5},
    {stack = {name = 'coin', count = 150, distance_factor = 1 / 8}, weight = 3},
    {stack = {name = 'raw-fish', count = 100, distance_factor = 1 / 8}, weight = 1},
    {stack = {name = 'piercing-shotgun-shell', count = 500, distance_factor = 1 / 8}, weight = 1},
    {stack = {name = 'flamethrower-ammo', count = 250, distance_factor = 1 / 8}, weight = 1},
    {stack = {name = 'rocket', count = 200, distance_factor = 1 / 8}, weight = 1},
    {stack = {name = 'explosive-rocket', count = 200, distance_factor = 1 / 8}, weight = 1},
    {stack = {name = 'gun-turret', count = 50, distance_factor = 1 / 16}, weight = 1},
    {stack = {name = 'flamethrower-turret', count = 25, distance_factor = 1 / 16}, weight = 1},
    {stack = {name = 'cluster-grenade', count = 50, distance_factor = 1 / 32}, weight = 1},
    {stack = {name = 'power-armor', count = 3, distance_factor = 1 / 128}, weight = 1},
    {stack = {name = 'solar-panel-equipment', count = 25, distance_factor = 1 / 32}, weight = 1},
    {stack = {name = 'battery-equipment', count = 25, distance_factor = 1 / 128}, weight = 1},
    {stack = {name = 'battery-mk2-equipment', count = 1, distance_factor = 1 / 128}, weight = 1},
    {stack = {name = 'energy-shield-equipment', count = 10, distance_factor = 1 / 64}, weight = 1},
    {stack = {name = 'energy-shield-mk2-equipment', count = 3, distance_factor = 1 / 64}, weight = 1},
    {stack = {name = 'exoskeleton-equipment', count = 3, distance_factor = 1 / 64}, weight = 1},
    {stack = {name = 'night-vision-equipment', count = 2, distance_factor = 1 / 64}, weight = 1}
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
        recipe = 'explosive-rocket',
        output = {min_rate = 0.25 / 60, distance_factor = 0.25 / 60 / 512, item = 'explosive-rocket'}
    }
}

local factory_b = {
    callback = ob.magic_item_crafting_callback,
    data = {
        recipe = 'cluster-grenade',
        output = {min_rate = 0.1 / 60, distance_factor = 0.1 / 60 / 512, item = 'cluster-grenade'}
    }
}

local factory_c = {
    callback = ob.magic_item_crafting_callback,
    data = {
        recipe = 'flamethrower-turret',
        output = {min_rate = 0.04 / 60, distance_factor = 0.04 / 60 / 512, item = 'flamethrower-turret'}
    }
}

local market = {
    callback = ob.market_set_items_callback,
    data = {
        market_name = 'Medium Weapon Factory',
        upgrade_rate = 0.5,
        upgrade_base_cost = 500,
        upgrade_cost_base = 2,
        {
            name = 'raw-fish',
            price = 1,
            distance_factor = 0.5 / 512,
            min_price = 0.1
        },
        {
            name = 'combat-shotgun',
            price = 125,
            distance_factor = 62.5 / 512,
            min_price = 62.5
        },
        {
            name = 'shotgun-shell',
            price = 1,
            distance_factor = 0.5 / 512,
            min_price = 0.1
        },
        {
            name = 'piercing-shotgun-shell',
            price = 3,
            distance_factor = 1.5 / 512,
            min_price = 0.3
        },
        {
            name = 'flamethrower',
            price = 175,
            distance_factor = 87.5 / 512,
            min_price = 87.5
        },
        {
            name = 'flamethrower-ammo',
            price = 7.5,
            distance_factor = 3.75 / 512,
            min_price = 0.75
        },
        {
            name = 'rocket-launcher',
            price = 250,
            distance_factor = 125 / 512,
            min_price = 125
        },
        {
            name = 'rocket',
            price = 10,
            distance_factor = 5 / 512,
            min_price = 1
        },
        {
            name = 'explosive-rocket',
            price = 20,
            distance_factor = 10 / 512,
            min_price = 2
        },
        {
            name = 'grenade',
            price = 5,
            distance_factor = 5 / 512,
            min_price = 0.5
        },
        {
            name = 'cluster-grenade',
            price = 50,
            distance_factor = 25 / 512,
            min_price = 5
        },
        {
            name = 'modular-armor',
            price = 175
        },
        {
            name = 'power-armor',
            price = 500,
            distance_factor = 250 / 512,
            min_price = 250
        },
        {
            name = 'solar-panel-equipment',
            price = 75,
            distance_factor = 37.5 / 512,
            min_price = 7.5
        },
        {
            name = 'fusion-reactor-equipment',
            price = 625,
            distance_factor = 312.5 / 512,
            min_price = 312.5
        },
        {
            name = 'battery-equipment',
            price = 50,
            distance_factor = 25 / 512,
            min_price = 5
        },
        {
            name = 'battery-mk2-equipment',
            price = 250,
            distance_factor = 125 / 512,
            min_price = 125
        },
        {
            name = 'energy-shield-equipment',
            price = 50,
            distance_factor = 37.5 / 512,
            min_price = 15
        },
        {
            name = 'energy-shield-mk2-equipment',
            price = 100,
            distance_factor = 50 / 512,
            min_price = 25
        },
        {
            name = 'exoskeleton-equipment',
            price = 100,
            distance_factor = 50 / 512,
            min_price = 10
        },
        {
            name = 'night-vision-equipment',
            price = 50,
            distance_factor = 25 / 512,
            min_price = 5
        },
        {
            name = 'gun-turret',
            price = 20,
            distance_factor = 10 / 512,
            min_price = 2
        },
        {
            name = 'flamethrower-turret',
            price = 50,
            distance_factor = 25 / 512,
            min_price = 5
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
