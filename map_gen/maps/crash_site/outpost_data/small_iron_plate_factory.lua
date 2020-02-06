local ob = require 'map_gen.maps.crash_site.outpost_builder'
local Token = require 'utils.token'

local loot = {
    {weight = 5},
    {stack = {name = 'coin', count = 50, distance_factor = 1 / 20}, weight = 5},
    {stack = {name = 'iron-ore', count = 1600}, weight = 8},
    {stack = {name = 'iron-plate', count = 500, distance_factor = 1 / 2}, weight = 10},
    {stack = {name = 'steel-plate', count = 250, distance_factor = 1 / 5}, weight = 2}
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
        furance_item = 'iron-ore',
        output = {min_rate = 2 / 60, distance_factor = 2 / 60 / 512, item = 'iron-plate'}
    }
}

local market = {
    callback = ob.market_set_items_callback,
    data = {
        market_name = 'Small Iron Plate Factory',
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
        }
    }
}

local turrets = require 'map_gen.maps.crash_site.outpost_data.light_gun_turrets'
local worms = require 'map_gen.maps.crash_site.outpost_data.big_worm_turrets'
worms = ob.extend_walls(worms, {max_count = 2, fallback = turrets})

local base_factory = require 'map_gen.maps.crash_site.outpost_data.small_furance'

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
    walls = {worms},
    bases = {
        {level4, level2}
    }
}
