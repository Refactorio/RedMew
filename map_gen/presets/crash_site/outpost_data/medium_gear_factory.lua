local ob = require 'map_gen.presets.crash_site.outpost_builder'
local Token = require 'utils.global_token'

local loot = {
    {weight = 10},
    {stack = {name = 'coin', count = 1000, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'iron-plate', count = 750, distance_factor = 1 / 2}, weight = 5},
    {stack = {name = 'steel-plate', count = 200, distance_factor = 1 / 5}, weight = 1},
    {stack = {name = 'iron-gear-wheel', count = 1500, distance_factor = 1}, weight = 5}
}

local weights = ob.prepare_weighted_loot(loot)

local loot_callback =
    Token.register(
    function(chest)
        ob.do_random_loot(chest, weights, loot)
    end
)

local level2 =
    ob.make_1_way {
    force = 'neutral',
    loot = {callback = loot_callback},
    [1] = {tile = 'concrete'},
    [2] = {tile = 'concrete'},
    [3] = {tile = 'concrete'},
    [4] = {tile = 'concrete'},
    [5] = {tile = 'concrete'},
    [6] = {tile = 'concrete'},
    [7] = {tile = 'concrete'},
    [8] = {entity = {name = 'iron-chest', callback = 'loot'}, tile = 'refined-concrete'},
    [9] = {entity = {name = 'iron-chest', callback = 'loot'}, tile = 'refined-concrete'},
    [10] = {entity = {name = 'iron-chest', callback = 'loot'}, tile = 'refined-concrete'},
    [11] = {entity = {name = 'iron-chest', callback = 'loot'}, tile = 'refined-concrete'},
    [12] = {tile = 'concrete'},
    [13] = {tile = 'concrete'},
    [14] = {entity = {name = 'iron-chest', callback = 'loot'}, tile = 'refined-concrete'},
    [15] = {entity = {name = 'iron-chest', callback = 'loot'}, tile = 'refined-concrete'},
    [16] = {entity = {name = 'iron-chest', callback = 'loot'}, tile = 'refined-concrete'},
    [17] = {entity = {name = 'iron-chest', callback = 'loot'}, tile = 'refined-concrete'},
    [18] = {tile = 'concrete'},
    [19] = {tile = 'concrete'},
    [20] = {entity = {name = 'iron-chest', callback = 'loot'}, tile = 'refined-concrete'},
    [21] = {entity = {name = 'iron-chest', callback = 'loot'}, tile = 'refined-concrete'},
    [22] = {entity = {name = 'iron-chest', callback = 'loot'}, tile = 'refined-concrete'},
    [23] = {entity = {name = 'iron-chest', callback = 'loot'}, tile = 'refined-concrete'},
    [24] = {tile = 'concrete'},
    [25] = {tile = 'concrete'},
    [26] = {entity = {name = 'iron-chest', callback = 'loot'}, tile = 'refined-concrete'},
    [27] = {entity = {name = 'iron-chest', callback = 'loot'}, tile = 'refined-concrete'},
    [28] = {entity = {name = 'iron-chest', callback = 'loot'}, tile = 'refined-concrete'},
    [29] = {entity = {name = 'iron-chest', callback = 'loot'}, tile = 'refined-concrete'},
    [30] = {tile = 'concrete'},
    [31] = {tile = 'concrete'},
    [32] = {tile = 'concrete'},
    [33] = {tile = 'concrete'},
    [34] = {tile = 'concrete'},
    [35] = {tile = 'concrete'},
    [36] = {tile = 'concrete'}
}

local level3 =
    ob.make_1_way {
    force = 'neutral',
    factory = {
        callback = ob.magic_item_crafting_callback,
        data = {
            recipe = 'iron-gear-wheel',
            output = {min_rate = 1 / 60, distance_factor = 1 / 60 / 100, item = 'iron-gear-wheel'}
        }
    },
    max_count = 6,
    fallback = level2,
    [1] = {tile = 'concrete'},
    [2] = {tile = 'concrete'},
    [3] = {tile = 'concrete'},
    [4] = {tile = 'concrete'},
    [5] = {tile = 'concrete'},
    [6] = {tile = 'concrete'},
    [7] = {tile = 'concrete'},
    [8] = {tile = 'refined-concrete'},
    [9] = {tile = 'refined-concrete'},
    [10] = {tile = 'refined-concrete'},
    [11] = {tile = 'refined-concrete'},
    [12] = {tile = 'concrete'},
    [13] = {tile = 'concrete'},
    [14] = {tile = 'refined-concrete'},
    [15] = {entity = {name = 'assembling-machine-2', callback = 'factory'}, tile = 'refined-concrete'},
    [16] = {tile = 'refined-concrete'},
    [17] = {tile = 'refined-concrete'},
    [18] = {tile = 'concrete'},
    [19] = {tile = 'concrete'},
    [20] = {tile = 'refined-concrete'},
    [21] = {tile = 'refined-concrete'},
    [22] = {tile = 'refined-concrete'},
    [23] = {tile = 'refined-concrete'},
    [24] = {tile = 'concrete'},
    [25] = {tile = 'concrete'},
    [26] = {tile = 'refined-concrete'},
    [27] = {tile = 'refined-concrete'},
    [28] = {tile = 'refined-concrete'},
    [29] = {tile = 'refined-concrete'},
    [30] = {tile = 'concrete'},
    [31] = {tile = 'concrete'},
    [32] = {tile = 'concrete'},
    [33] = {tile = 'concrete'},
    [34] = {tile = 'concrete'},
    [35] = {tile = 'concrete'},
    [36] = {tile = 'concrete'}
}

local level4 =
    ob.make_1_way {
    force = 'neutral',
    market = {
        callback = ob.market_set_items_callback,
        data = {
            {
                offer = {type = 'give-item', item = 'iron-gear-wheel', count = 100},
                name = 'coin',
                price = 100,
                distance_factor = 1 / 32,
                min_price = 10
            },
            {
                offer = {type = 'give-item', item = 'iron-plate', count = 100},
                name = 'coin',
                price = 80,
                distance_factor = 1 / 32,
                min_price = 8
            },
            {
                offer = {type = 'give-item', item = 'steel-plate', count = 100},
                name = 'coin',
                price = 400,
                distance_factor = 1 / 32,
                min_price = 40
            }
        }
    },
    max_count = 1,
    fallback = level3,
    [1] = {tile = 'concrete'},
    [2] = {tile = 'concrete'},
    [3] = {tile = 'concrete'},
    [4] = {tile = 'concrete'},
    [5] = {tile = 'concrete'},
    [6] = {tile = 'concrete'},
    [7] = {tile = 'concrete'},
    [8] = {tile = 'refined-concrete'},
    [9] = {tile = 'refined-concrete'},
    [10] = {tile = 'refined-concrete'},
    [11] = {tile = 'refined-concrete'},
    [12] = {tile = 'concrete'},
    [13] = {tile = 'concrete'},
    [14] = {tile = 'refined-concrete'},
    [15] = {entity = {name = 'market', callback = 'market'}},
    [16] = {tile = 'refined-concrete'},
    [17] = {tile = 'refined-concrete'},
    [18] = {tile = 'concrete'},
    [19] = {tile = 'concrete'},
    [20] = {tile = 'refined-concrete'},
    [21] = {tile = 'refined-concrete'},
    [22] = {tile = 'refined-concrete'},
    [23] = {tile = 'refined-concrete'},
    [24] = {tile = 'concrete'},
    [25] = {tile = 'concrete'},
    [26] = {tile = 'refined-concrete'},
    [27] = {tile = 'refined-concrete'},
    [28] = {tile = 'refined-concrete'},
    [29] = {tile = 'refined-concrete'},
    [30] = {tile = 'concrete'},
    [31] = {tile = 'concrete'},
    [32] = {tile = 'concrete'},
    [33] = {tile = 'concrete'},
    [34] = {tile = 'concrete'},
    [35] = {tile = 'concrete'},
    [36] = {tile = 'concrete'}
}

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
