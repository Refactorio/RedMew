local ob = require 'map_gen.maps.crash_site.outpost_builder'
local Token = require 'utils.token'

local loot = {
    {weight = 5},
    {stack = {name = 'coin', count = 500, distance_factor = 1 / 8}, weight = 3},
    {stack = {name = 'raw-fish', count = 250, distance_factor = 1}, weight = 1},
    {stack = {name = 'explosive-rocket', count = 500, distance_factor = 1}, weight = 1},
    {stack = {name = 'laser-turret', count = 50, distance_factor = 1 / 8}, weight = 1},
    {stack = {name = 'cluster-grenade', count = 250, distance_factor = 1}, weight = 1},
    {stack = {name = 'destroyer-capsule', count = 50, distance_factor = 1 / 8}, weight = 1},
    {stack = {name = 'power-armor-mk2', count = 5, distance_factor = 1 / 256}, weight = 1},
    {stack = {name = 'fusion-reactor-equipment', count = 5, distance_factor = 1 / 256}, weight = 1},
    {stack = {name = 'battery-mk2-equipment', count = 5, distance_factor = 1 / 128}, weight = 1},
    {stack = {name = 'energy-shield-mk2-equipment', count = 5, distance_factor = 1 / 64}, weight = 1},
    {stack = {name = 'exoskeleton-equipment', count = 5, distance_factor = 1 / 64}, weight = 1},
    {stack = {name = 'personal-laser-defense-equipment', count = 5, distance_factor = 1 / 64}, weight = 1}
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
        recipe = 'destroyer-capsule',
        output = {min_rate = 0.025 / 60, distance_factor = 0.025 / 60 / 512, item = 'destroyer-capsule'}
    }
}

local factory_b = {
    callback = ob.magic_item_crafting_callback,
    data = {
        recipe = 'laser-turret',
        output = {min_rate = 0.025 / 60, distance_factor = 0.025 / 60 / 512, item = 'laser-turret'}
    }
}

local market = {
    callback = ob.market_set_items_callback,
    data = {
        market_name = 'Big Weapon Factory',
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
            name = 'destroyer-capsule',
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
            name = 'power-armor-mk2',
            price = 1000,
            distance_factor = 500 / 512,
            min_price = 250
        },
        {
            name = 'solar-panel-equipment',
            price = 10,
            distance_factor = 5 / 512,
            min_price = 1
        },
        {
            name = 'fusion-reactor-equipment',
            price = 250,
            distance_factor = 125 / 512,
            min_price = 75
        },
        {
            name = 'battery-equipment',
            price = 10,
            distance_factor = 5 / 512,
            min_price = 1
        },
        {
            name = 'battery-mk2-equipment',
            price = 50,
            distance_factor = 25 / 512,
            min_price = 5
        },
        {
            name = 'energy-shield-equipment',
            price = 10,
            distance_factor = 5 / 512,
            min_price = 1
        },
        {
            name = 'energy-shield-mk2-equipment',
            price = 50,
            distance_factor = 25 / 512,
            min_price = 5
        },
        {
            name = 'exoskeleton-equipment',
            price = 50,
            distance_factor = 25 / 512,
            min_price = 5
        },
        {
            name = 'night-vision-equipment',
            price = 10,
            distance_factor = 5 / 512,
            min_price = 1
        },
        {
            name = 'personal-laser-defense-equipment',
            price = 100,
            distance_factor = 50 / 512,
            min_price = 10
        },
        {
            name = 'tank-machine-gun',
            price = 2000
        },
        {
            name = 'tank-cannon',
            price = 1000
        },
        {
            name = 'artillery-wagon-cannon',
            price = 4000
        },
        {
            name = 'gun-turret',
            price = 10,
            distance_factor = 5 / 512,
            min_price = 1
        },
        {
            name = 'flamethrower-turret',
            price = 20,
            distance_factor = 10 / 512,
            min_price = 2
        },
        {
            name = 'laser-turret',
            price = 30,
            distance_factor = 15 / 512,
            min_price = 3
        }
    }
}

local base_factory = require 'map_gen.maps.crash_site.outpost_data.big_factory'

local level2 = ob.extend_1_way(base_factory[1], {loot = {callback = loot_callback}})
local level3 =
    ob.extend_1_way(
    base_factory[2],
    {
        factory = factory,
        fallback = level2,
        max_count = 3
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
    require 'map_gen.maps.crash_site.outpost_data.artillery_block',
    {fallback = level4, max_count = 1}
)

return {
    settings = {
        blocks = 11,
        variance = 3,
        min_step = 2,
        max_level = 4
    },
    walls = {
        require 'map_gen.maps.crash_site.outpost_data.heavy_gun_turrets',
        require 'map_gen.maps.crash_site.outpost_data.heavy_laser_turrets',
        require 'map_gen.maps.crash_site.outpost_data.heavy_flame_turrets'
    },
    bases = {
        {require 'map_gen.maps.crash_site.outpost_data.laser_block'},
        {level2},
        {artillery}
    }
}
