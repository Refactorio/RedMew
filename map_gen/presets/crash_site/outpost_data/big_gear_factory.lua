local ob = require 'map_gen.presets.crash_site.outpost_builder'
local Token = require 'utils.global_token'

local loot = {
    {weight = 10},
    {stack = {name = 'coin', count = 250, distance_factor = 1 / 20}, weight = 5},
    {stack = {name = 'iron-plate', count = 2500, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'steel-plate', count = 1000, distance_factor = 1 / 5}, weight = 1},
    {stack = {name = 'iron-gear-wheel', count = 4000, distance_factor = 1}, weight = 5}
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
        recipe = 'iron-gear-wheel',
        output = {min_rate = 1 / 60, distance_factor = 1 / 60 / 512, item = 'iron-gear-wheel'}
    }
}

local market = {
    callback = ob.market_set_items_callback,
    data = {
        {
            name = 'iron-gear-wheel',
            price = 0.5,
            distance_factor = 0.25 / 512,
            min_price = 0.05
        },
        {
            name = 'iron-plate',
            price = 0.4,
            distance_factor = 0.2 / 512,
            min_price = 0.04
        },
        {
            name = 'steel-plate',
            price = 2,
            distance_factor = 1 / 512,
            min_price = 0.2
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
        blocks = 9,
        variance = 3,
        min_step = 2,
        max_level = 2
    },
    walls = {
        require 'map_gen.presets.crash_site.outpost_data.heavy_gun_turrets'
    },
    bases = {
        {level4, level2}
    }
}
