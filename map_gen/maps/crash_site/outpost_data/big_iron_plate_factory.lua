local ob = require 'map_gen.maps.crash_site.outpost_builder'
local Token = require 'utils.token'

local loot = {
    {weight = 5},
    {stack = {name = 'coin', count = 250, distance_factor = 1 / 20}, weight = 5},
    {stack = {name = 'iron-ore', count = 2400}, weight = 2},
    {stack = {name = 'iron-plate', count = 1500, distance_factor = 1 / 2}, weight = 10},
    {stack = {name = 'steel-plate', count = 1000, distance_factor = 1 / 5}, weight = 8},
    {stack = {name = 'steel-plate', count = 1000, distance_factor = 1 / 5}, weight = 8},
    {stack = {name = 'low-density-structure', count = 30, distance_factor = 1 / 20}, weight = 2}
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
        furance_item = {name = 'iron-ore', count = 100},
        output = {min_rate = 2.5 / 60, distance_factor = 2.5 / 60 / 512, item = 'iron-plate'}
    }
}

local factory_b = {
    callback = ob.magic_item_crafting_callback,
    data = {
        furance_item = {name = 'iron-plate', count = 100},
        output = {min_rate = 1.5 / 60, distance_factor = 1.5 / 60 / 512, item = 'steel-plate'}
    }
}

local factory_c = {
    callback = ob.magic_item_crafting_callback,
    data = {
        recipe = 'low-density-structure',
        output = {min_rate = 0.1 / 60, distance_factor = 0.1 / 60 / 512, item = 'low-density-structure'}
    }
}

local market = {
    callback = ob.market_set_items_callback,
    data = {
        market_name = 'Big Iron Plate Factory',
        upgrade_rate = 0.5,
        upgrade_base_cost = 250,
        upgrade_cost_base = 2,
        {
            name = 'iron-plate',
            price = 0.3,
            distance_factor = 0.15 / 512,
            min_price = 0.03
        },
        {
            name = 'steel-plate',
            price = 1.5,
            distance_factor = 0.75 / 512,
            min_price = 0.15
        },
        {
            name = 'low-density-structure',
            price = 25,
            distance_factor = 12.5 / 512,
            min_price = 2.5
        }
    }
}

local base_factory = require 'map_gen.maps.crash_site.outpost_data.medium_furance'
local base_factory2 = require 'map_gen.maps.crash_site.outpost_data.big_factory'

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
        fallback = level2
    }
)

local level3c =
    ob.extend_1_way(
    base_factory2[2],
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
        blocks = 9,
        variance = 3,
        min_step = 2,
        max_level = 3
    },
    walls = {
        require 'map_gen.maps.crash_site.outpost_data.heavy_gun_turrets'
    },
    bases = {
        {level2, level3},
        {level4}
    }
}
