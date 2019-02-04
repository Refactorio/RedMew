local ob = require 'map_gen.maps.crash_site.outpost_builder'
local Token = require 'utils.token'

local loot = {
    {weight = 10},
    {stack = {name = 'coin', count = 250, distance_factor = 1 / 20}, weight = 5},
    {stack = {name = 'crude-oil-barrel', count = 200, distance_factor = 1 / 20}, weight = 2},
    {stack = {name = 'heavy-oil-barrel', count = 200, distance_factor = 1 / 20}, weight = 2},
    {stack = {name = 'light-oil-barrel', count = 200, distance_factor = 1 / 20}, weight = 2},
    {stack = {name = 'petroleum-gas-barrel', count = 200, distance_factor = 1 / 20}, weight = 2},
    {stack = {name = 'lubricant-barrel', count = 200, distance_factor = 1 / 20}, weight = 1},
    {stack = {name = 'sulfuric-acid-barrel', count = 200, distance_factor = 1 / 20}, weight = 1}
}

local weights = ob.prepare_weighted_loot(loot)

local loot_callback =
    Token.register(
    function(chest)
        ob.do_random_loot(chest, weights, loot)
    end
)

local fluid_loot = {
    {stack = {name = 'petroleum-gas', count = 25000}, weight = 1},
    {stack = {name = 'sulfuric-acid', count = 25000}, weight = 1}
}

local fluid_weights = ob.prepare_weighted_loot(fluid_loot)

local fluid_loot_callback =
    Token.register(
    function(chest)
        ob.do_random_fluid_loot(chest, fluid_weights, fluid_loot)
    end
)

local factory = {
    callback = ob.magic_item_crafting_callback,
    data = {
        recipe = 'advanced-oil-processing',
        keep_active = true,
        output = {
            {min_rate = 1.25 / 60, distance_factor = 1.25 / 60 / 512, item = 'heavy-oil', fluidbox_index = 3},
            {min_rate = 5.625/ 60, distance_factor = 5.625 / 60 / 512, item = 'light-oil', fluidbox_index = 4},
            {min_rate = 6.875 / 60, distance_factor = 6.875 / 60 / 512, item = 'petroleum-gas', fluidbox_index = 5}
        }
    }
}

local market = {
    callback = ob.market_set_items_callback,
    data = {
        market_name = 'Big Oil Refinery',
        upgrade_rate = 0.5,
        upgrade_base_cost = 150,
        upgrade_cost_base = 2,
        {
            name = 'crude-oil-barrel',
            price = 1,
            distance_factor = 5 / 512,
            min_price = 0.1
        },
        {
            name = 'heavy-oil-barrel',
            price = 1.5,
            distance_factor = 7.5 / 512,
            min_price = 0.15
        },
        {
            name = 'light-oil-barrel',
            price = 2,
            distance_factor = 10 / 512,
            min_price = 0.2
        },
        {
            name = 'petroleum-gas-barrel',
            price = 2.5,
            distance_factor = 12.5 / 512,
            min_price = 0.25
        },
        {
            name = 'lubricant-barrel',
            price = 1.5,
            distance_factor = 7.5 / 512,
            min_price = 0.15
        },
        {
            name = 'sulfuric-acid-barrel',
            price = 4,
            distance_factor = 20 / 512,
            min_price = 0.4
        }
    }
}

local base_factory = require 'map_gen.maps.crash_site.outpost_data.big_refinery'
local storage_tank = require 'map_gen.maps.crash_site.outpost_data.storage_tank_block'

local level2 = ob.extend_1_way(base_factory[1], {loot = {callback = loot_callback}})

local level2b =
    ob.extend_1_way(
    storage_tank,
    {
        tank = {callback = fluid_loot_callback},
        fallback = level2,
        max_count = 3
    }
)

local level3 =
    ob.extend_1_way(
    base_factory[2],
    {
        factory = factory,
        fallback = level2b,
        max_count = 6
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
        require 'map_gen.maps.crash_site.outpost_data.heavy_flame_turrets'
    },
    bases = {
        {level4, level2}
    }
}
