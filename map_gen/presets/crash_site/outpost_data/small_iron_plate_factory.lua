local ob = require 'map_gen.presets.crash_site.outpost_builder'
local Token = require 'utils.global_token'

local loot = {
    {weight = 5},
    {stack = {name = 'coin', count = 500, distance_factor = 1 / 2}, weight = 5},
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

local level2 =
    ob.make_1_way {
    force = 'neutral',
    loot = {callback = loot_callback},
    [1] = {tile = 'stone-path'},
    [2] = {tile = 'stone-path'},
    [3] = {tile = 'stone-path'},
    [4] = {tile = 'stone-path'},
    [5] = {tile = 'stone-path'},
    [6] = {tile = 'stone-path'},
    [7] = {tile = 'stone-path'},
    [8] = {entity = {name = 'iron-chest', callback = 'loot'}, tile = 'concrete'},
    [9] = {entity = {name = 'iron-chest', callback = 'loot'}, tile = 'concrete'},
    [10] = {entity = {name = 'iron-chest', callback = 'loot'}, tile = 'concrete'},
    [11] = {entity = {name = 'iron-chest', callback = 'loot'}, tile = 'concrete'},
    [12] = {tile = 'stone-path'},
    [13] = {tile = 'stone-path'},
    [14] = {entity = {name = 'iron-chest', callback = 'loot'}, tile = 'concrete'},
    [15] = {entity = {name = 'iron-chest', callback = 'loot'}, tile = 'concrete'},
    [16] = {entity = {name = 'iron-chest', callback = 'loot'}, tile = 'concrete'},
    [17] = {entity = {name = 'iron-chest', callback = 'loot'}, tile = 'concrete'},
    [18] = {tile = 'stone-path'},
    [19] = {tile = 'stone-path'},
    [20] = {entity = {name = 'iron-chest', callback = 'loot'}, tile = 'concrete'},
    [21] = {entity = {name = 'iron-chest', callback = 'loot'}, tile = 'concrete'},
    [22] = {entity = {name = 'iron-chest', callback = 'loot'}, tile = 'concrete'},
    [23] = {entity = {name = 'iron-chest', callback = 'loot'}, tile = 'concrete'},
    [24] = {tile = 'stone-path'},
    [25] = {tile = 'stone-path'},
    [26] = {entity = {name = 'iron-chest', callback = 'loot'}, tile = 'concrete'},
    [27] = {entity = {name = 'iron-chest', callback = 'loot'}, tile = 'concrete'},
    [28] = {entity = {name = 'iron-chest', callback = 'loot'}, tile = 'concrete'},
    [29] = {entity = {name = 'iron-chest', callback = 'loot'}, tile = 'concrete'},
    [30] = {tile = 'stone-path'},
    [31] = {tile = 'stone-path'},
    [32] = {tile = 'stone-path'},
    [33] = {tile = 'stone-path'},
    [34] = {tile = 'stone-path'},
    [35] = {tile = 'stone-path'},
    [36] = {tile = 'stone-path'}
}

local level3 =
    ob.make_1_way {
    force = 'neutral',
    factory = {
        callback = ob.magic_item_crafting_callback,
        data = {
            furance_item = 'iron-ore',
            output = {min_rate = 1.5 / 60, distance_factor = 1.5 / 60 / 100, item = 'iron-plate'}
        }
    },
    max_count = 4,
    fallback = level2,
    [1] = {tile = 'stone-path'},
    [2] = {tile = 'stone-path'},
    [3] = {tile = 'stone-path'},
    [4] = {tile = 'stone-path'},
    [5] = {tile = 'stone-path'},
    [6] = {tile = 'stone-path'},
    [7] = {tile = 'stone-path'},
    [8] = {tile = 'concrete'},
    [9] = {tile = 'concrete'},
    [10] = {tile = 'concrete'},
    [11] = {tile = 'concrete'},
    [12] = {tile = 'stone-path'},
    [13] = {tile = 'stone-path'},
    [14] = {tile = 'concrete'},
    [15] = {entity = {name = 'electric-furnace', callback = 'factory'}, tile = 'concrete'},
    [16] = {tile = 'concrete'},
    [17] = {tile = 'concrete'},
    [18] = {tile = 'stone-path'},
    [19] = {tile = 'stone-path'},
    [20] = {tile = 'concrete'},
    [21] = {tile = 'concrete'},
    [22] = {tile = 'concrete'},
    [23] = {tile = 'concrete'},
    [24] = {tile = 'stone-path'},
    [25] = {tile = 'stone-path'},
    [26] = {tile = 'concrete'},
    [27] = {tile = 'concrete'},
    [28] = {tile = 'concrete'},
    [29] = {tile = 'concrete'},
    [30] = {tile = 'stone-path'},
    [31] = {tile = 'stone-path'},
    [32] = {tile = 'stone-path'},
    [33] = {tile = 'stone-path'},
    [34] = {tile = 'stone-path'},
    [35] = {tile = 'stone-path'},
    [36] = {tile = 'stone-path'}
}

local level4 =
    ob.make_1_way {
    force = 'neutral',
    market = {
        callback = ob.market_set_items_callback,
        data = {
            {
                offer = {type = 'give-item', item = 'iron-plate', count = 100},
                name = 'coin',
                price = 60,
                distance_factor = 1 / 32,
                min_price = 6
            },
            {
                offer = {type = 'give-item', item = 'steel-plate', count = 100},
                name = 'coin',
                price = 300,
                distance_factor = 1 / 32,
                min_price = 30
            }
        }
    },
    max_count = 1,
    fallback = level3,
    [1] = {tile = 'stone-path'},
    [2] = {tile = 'stone-path'},
    [3] = {tile = 'stone-path'},
    [4] = {tile = 'stone-path'},
    [5] = {tile = 'stone-path'},
    [6] = {tile = 'stone-path'},
    [7] = {tile = 'stone-path'},
    [8] = {tile = 'concrete'},
    [9] = {tile = 'concrete'},
    [10] = {tile = 'concrete'},
    [11] = {tile = 'concrete'},
    [12] = {tile = 'stone-path'},
    [13] = {tile = 'stone-path'},
    [14] = {tile = 'concrete'},
    [15] = {entity = {name = 'market', callback = 'market'}},
    [16] = {tile = 'concrete'},
    [17] = {tile = 'concrete'},
    [18] = {tile = 'stone-path'},
    [19] = {tile = 'stone-path'},
    [20] = {tile = 'concrete'},
    [21] = {tile = 'concrete'},
    [22] = {tile = 'concrete'},
    [23] = {tile = 'concrete'},
    [24] = {tile = 'stone-path'},
    [25] = {tile = 'stone-path'},
    [26] = {tile = 'concrete'},
    [27] = {tile = 'concrete'},
    [28] = {tile = 'concrete'},
    [29] = {tile = 'concrete'},
    [30] = {tile = 'stone-path'},
    [31] = {tile = 'stone-path'},
    [32] = {tile = 'stone-path'},
    [33] = {tile = 'stone-path'},
    [34] = {tile = 'stone-path'},
    [35] = {tile = 'stone-path'},
    [36] = {tile = 'stone-path'}
}

return {
    settings = {
        blocks = 6,
        variance = 3,
        min_step = 2,
        max_level = 2
    },
    walls = {
        require 'map_gen.presets.crash_site.outpost_data.light_gun_turrets'
    },
    bases = {
        {level4, level2}
    }
}
