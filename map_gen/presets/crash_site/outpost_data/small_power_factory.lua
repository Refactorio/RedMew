local ob = require 'map_gen.presets.crash_site.outpost_builder'
local Token = require 'utils.global_token'

local loot = {
    {weight = 10},
    {stack = {name = 'coin', count = 50, distance_factor = 1 / 20}, weight = 5},
    {stack = {name = 'coal', count = 1000, distance_factor = 1}, weight = 5},
    {stack = {name = 'solid-fuel', count = 500, distance_factor = 1}, weight = 5},
    {stack = {name = 'boiler', count = 25, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'steam-engine', count = 50, distance_factor = 1 / 5}, weight = 5},
    {stack = {name = 'offshore-pump', count = 5, distance_factor = 1}, weight = 5},
    {stack = {name = 'pipe', count = 200, distance_factor = 1}, weight = 5},
    {stack = {name = 'pipe-to-ground', count = 50, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'medium-electric-pole', count = 50, distance_factor = 1 / 2}, weight = 5}
}

local weights = ob.prepare_weighted_loot(loot)

local loot_callback =
    Token.register(
    function(chest)
        ob.do_random_loot(chest, weights, loot)
    end
)

local market = {
    callback = ob.market_set_items_callback,
    data = {
        {
            name = 'coal',
            price = 0.5,
            distance_factor = 0.25 / 512,
            min_price = 0.05
        },
        {
            name = 'solid-fuel',
            price = 1.25,
            distance_factor = 0.75 / 512,
            min_price = 0.125
        },
        {
            name = 'boiler',
            price = 3,
            distance_factor = 1.5 / 512,
            min_price = 0.3
        },
        {
            name = 'steam-engine',
            price = 6,
            distance_factor = 3 / 512,
            min_price = 0.6
        },
        {
            name = 'offshore-pump',
            price = 2,
            distance_factor = 1 / 512,
            min_price = 0.2
        },
        {
            name = 'pipe',
            price = 0.25,
            distance_factor = 0.125 / 512,
            min_price = 0.025
        },
        {
            name = 'pipe-to-ground',
            price = 2.5,
            distance_factor = 1.25 / 512,
            min_price = 0.25
        },
        {
            name = 'medium-electric-pole',
            price = 2,
            distance_factor = 1 / 512,
            min_price = 0.2
        }
    }
}

local base_factory = require 'map_gen.presets.crash_site.outpost_data.small_factory'
local power_factory = require 'map_gen.presets.crash_site.outpost_data.steam_engine_block'

local level2 = ob.extend_1_way(base_factory[1], {loot = {callback = loot_callback}})
local level3 =
    ob.extend_1_way(
    power_factory,
    {
        power = power,
        fallback = level2,
        max_count = 4
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
        --require 'map_gen.presets.crash_site.outpost_data.light_gun_turrets',
        --require 'map_gen.presets.crash_site.outpost_data.light_laser_turrets'
        require 'map_gen.presets.crash_site.outpost_data.walls'
    },
    bases = {
        {level4, level2}
    }
}
