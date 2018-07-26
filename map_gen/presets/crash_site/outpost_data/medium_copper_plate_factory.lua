local ob = require 'map_gen.presets.crash_site.outpost_builder'
local Token = require 'utils.global_token'

local loot = {
    {weight = 5},
    {stack = {name = 'coin', count = 750, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'copper-ore', count = 2400}, weight = 8},
    {stack = {name = 'copper-cable', count = 750, distance_factor = 1 / 2}, weight = 2},
    {stack = {name = 'copper-plate', count = 750, distance_factor = 1 / 5}, weight = 10}
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
        furance_item = 'copper-ore',
        output = {min_rate = 1.5 / 60, distance_factor = 1.5 / 60 / 100, item = 'copper-plate'}
    }
}

local market = {
    callback = ob.market_set_items_callback,
    data = {
        {
            name = 'copper-cable',
            price = 0.12,
            distance_factor = 0.005 / 32,
            min_price = 0.012
        },
        {
            name = 'copper-plate',
            price = 0.3,
            distance_factor = 0.005 / 32,
            min_price = 0.03
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
        blocks = 7,
        variance = 3,
        min_step = 2,
        max_level = 2
    },
    walls = {
        require 'map_gen.presets.crash_site.outpost_data.medium_gun_turrets'
    },
    bases = {
        {level4, level2}
    }
}
