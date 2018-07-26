local ob = require 'map_gen.presets.crash_site.outpost_builder'
local Token = require 'utils.global_token'

local loot = {
    {weight = 5},
    {stack = {name = 'coin', count = 2500, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'iron-ore', count = 2400}, weight = 2},
    {stack = {name = 'iron-plate', count = 1500, distance_factor = 1 / 2}, weight = 10},
    {stack = {name = 'steel-plate', count = 1000, distance_factor = 1 / 5}, weight = 8}
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
        output = {min_rate = 1.5 / 60, distance_factor = 1.5 / 60 / 100, item = 'iron-plate'}
    }
}

local factory_b = {
    callback = ob.magic_item_crafting_callback,
    data = {
        furance_item = {name = 'iron-plate', count = 100},
        output = {min_rate = 1.5 / 60, distance_factor = 1.5 / 60 / 100, item = 'steel-plate'}
    }
}

local market = {
    callback = ob.market_set_items_callback,
    data = {
        {
            name = 'iron-plate',
            price = 0.3,
            distance_factor = 0.005 / 32,
            min_price = 0.03
        },
        {
            name = 'steel-plate',
            price = 1.5,
            distance_factor = 0.005 / 32,
            min_price = 0.15
        }
    }
}

local base_factory = require 'map_gen.presets.crash_site.outpost_data.medium_furance'

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
        blocks = 9,
        variance = 3,
        min_step = 2,
        max_level = 3
    },
    walls = {
        require 'map_gen.presets.crash_site.outpost_data.heavy_gun_turrets'
    },
    bases = {
        {level2, level3},
        {level4}
    }
}
