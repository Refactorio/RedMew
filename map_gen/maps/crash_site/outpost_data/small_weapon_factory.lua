local ob = require 'map_gen.maps.crash_site.outpost_builder'
local Token = require 'utils.token'

local loot = {
    {weight = 5},
    {stack = {name = 'coin', count = 100, distance_factor = 1 / 8}, weight = 3},
    {stack = {name = 'raw-fish', count = 50, distance_factor = 1 / 16}, weight = 1},
    {stack = {name = 'combat-shotgun', count = 3, distance_factor = 1 / 128}, weight = 1},
    {stack = {name = 'shotgun-shell', count = 200, distance_factor = 1 / 8}, weight = 1},
    {stack = {name = 'piercing-shotgun-shell', count = 50, distance_factor = 1 / 8}, weight = 1},
    {stack = {name = 'flamethrower', count = 5, distance_factor = 1 / 128}, weight = 1},
    {stack = {name = 'flamethrower-ammo', count = 50, distance_factor = 1 / 8}, weight = 1},
    {stack = {name = 'rocket-launcher', count = 5, distance_factor = 1 / 128}, weight = 1},
    {stack = {name = 'rocket', count = 50, distance_factor = 1 / 8}, weight = 1},
    {stack = {name = 'gun-turret', count = 25, distance_factor = 1 / 16}, weight = 1},
    {stack = {name = 'flamethrower-turret', count = 15, distance_factor = 1 / 16}, weight = 1},
    {stack = {name = 'grenade', count = 100, distance_factor = 1 / 8}, weight = 1},
    {stack = {name = 'cluster-grenade', count = 10, distance_factor = 1 / 32}, weight = 1},
    {stack = {name = 'modular-armor', count = 3, distance_factor = 1 / 128}, weight = 1},
    {stack = {name = 'solar-panel-equipment', count = 12, distance_factor = 1 / 32}, weight = 1},
    {stack = {name = 'battery-equipment', count = 4, distance_factor = 1 / 128}, weight = 1},
    {stack = {name = 'energy-shield-equipment', count = 6, distance_factor = 1 / 64}, weight = 1}
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
        recipe = 'piercing-shotgun-shell',
        output = {min_rate = 0.125 / 60, distance_factor = 0.125 / 60 / 512, item = 'piercing-shotgun-shell'}
    }
}

local factory_b = {
    callback = ob.magic_item_crafting_callback,
    data = {
        recipe = 'rocket',
        output = {min_rate = 0.1 / 60, distance_factor = 0.1 / 60 / 512, item = 'rocket'}
    }
}

local factory_c = {
    callback = ob.magic_item_crafting_callback,
    data = {
        recipe = 'gun-turret',
        output = {min_rate = 0.05 / 60, distance_factor = 0.05 / 60 / 512, item = 'gun-turret'}
    }
}

local market = {
    callback = ob.market_set_items_callback,
    data = {
        market_name = 'Small Weapon Factory',
        upgrade_rate = 0.5,
        upgrade_base_cost = 350,
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
            price = 100,
            distance_factor = 50 / 512,
            min_price = 10
        },
        {
            name = 'modular-armor',
            price = 350,
            distance_factor = 175 / 512,
            min_price = 175
        },
        {
            name = 'solar-panel-equipment',
            price = 75,
            distance_factor = 37.5 / 512,
            min_price = 37.5
        },
        {
            name = 'battery-equipment',
            price = 50,
            distance_factor = 25 / 512,
            min_price = 25
        },
        {
            name = 'energy-shield-equipment',
            price = 75,
            distance_factor = 37.5 / 512,
            min_price = 37.5
        },
        {
            name = 'gun-turret',
            price = 20,
            distance_factor = 10 / 512,
            min_price = 2
        },
        {
            name = 'flamethrower-turret',
            price = 100,
            distance_factor = 50 / 512,
            min_price = 50
        }
    }
}

local base_factory = require 'map_gen.maps.crash_site.outpost_data.small_factory'

local level2 = ob.extend_1_way(base_factory[1], {loot = {callback = loot_callback}})
local level3 =
    ob.extend_1_way(
    base_factory[2],
    {
        factory = factory,
        fallback = level2,
        max_count = 1
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
        require 'map_gen.maps.crash_site.outpost_data.medium_gun_turrets',
        require 'map_gen.maps.crash_site.outpost_data.medium_laser_turrets',
        require 'map_gen.maps.crash_site.outpost_data.medium_flame_turrets'
    },
    bases = {
        {level4, level3b, level2}
    }
}
