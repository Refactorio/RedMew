local ob = require 'map_gen.presets.crash_site.outpost_builder'

local Token = require 'utils.global_token'

local loot = {
    {weight = 10},
    {stack = {name = 'coin', count = 500, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'iron-plate', count = 200, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'copper-cable', count = 300, distance_factor = 3 / 4}, weight = 5},
    {stack = {name = 'electronic-circuit', count = 400, distance_factor = 1}, weight = 5},
    {stack = {name = 'advanced-circuit', count = 200, distance_factor = 1 / 10}, weight = 1}
}

local factory = {
    callback = ob.magic_item_crafting_callback,
    data = {
        recipe = 'electronic-circuit',
        output = {min_rate = 1 / 60, distance_factor = 1 / 60 / 100, item = 'electronic-circuit'}
    }
}

local market = {
    callback = ob.market_set_items_callback,
    data = {
        {
            name = 'copper-cable',
            price = 50 / 200,
            distance_factor = 1 / 200 / 32,
            min_price = 5 / 200
        },
        {
            name = 'electronic-circuit',
            price = 200 / 200,
            distance_factor = 1 / 200 / 32,
            min_price = 10 / 200
        },
        {
            name = 'advanced-circuit',
            price = 2000 / 200,
            distance_factor = 1 / 200 / 32,
            min_price = 100 / 200
        }
    }
}

local weights = ob.prepare_weighted_loot(loot)

local loot_callback =
    Token.register(
    function(chest)
        ob.do_random_loot(chest, weights, loot)
    end
)

local base_factory = require 'map_gen.presets.crash_site.outpost_data.small_factory'

local level2 = ob.extend_1_way(base_factory[1], {loot = {callback = loot_callback}})
local level3 =
    ob.extend_1_way(
    base_factory[2],
    {
        factory = factory,
        fallback = level2
    }
)
local level4 =
    ob.extend_1_way(
    base_factory[3],
    {
        market = market,
        fallback = level3
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
        require 'map_gen.presets.crash_site.outpost_data.light_laser_turrets'
    },
    bases = {
        {level4, level2}
    }
}
