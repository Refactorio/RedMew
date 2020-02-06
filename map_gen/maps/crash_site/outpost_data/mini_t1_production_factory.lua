local ob = require 'map_gen.maps.crash_site.outpost_builder'
local Token = require 'utils.token'

local loot = {
    {weight = 10},
    {stack = {name = 'coin', count = 100, distance_factor = 1 / 8}, weight = 5},
    {stack = {name = 'steel-furnace', count = 24, distance_factor = 1 / 32}, weight = 3},
    {stack = {name = 'electric-mining-drill', count = 25, distance_factor = 1 / 24}, weight = 3},
    {stack = {name = 'storage-tank', count = 5, distance_factor = 1 / 24}, weight = 2},
    {stack = {name = 'pumpjack', count = 2, distance_factor = 1 / 64}, weight = 2},
    {stack = {name = 'oil-refinery', count = 1, distance_factor = 1 / 64}, weight = 1}
}

local weights = ob.prepare_weighted_loot(loot)

local loot_callback =
    Token.register(
    function(chest)
        ob.do_random_loot(chest, weights, loot)
    end
)

local factory_loot = {
    {
        stack = {
            recipe = 'steel-furnace',
            output = {item = 'steel-furnace', min_rate = 1 / 6 / 60, distance_factor = 1 / 6 / 60 / 512}
        },
        weight = 3
    },
    {
        stack = {
            recipe = 'electric-mining-drill',
            output = {item = 'electric-mining-drill', min_rate = 1 / 3 / 60, distance_factor = 1 / 3 / 60 / 512}
        },
        weight = 3
    },
    {
        stack = {
            recipe = 'pumpjack',
            output = {item = 'pumpjack', min_rate = 1 / 20 / 60, distance_factor = 1 / 20 / 60 / 512}
        },
        weight = 2
    },
    {
        stack = {
            recipe = 'oil-refinery',
            output = {item = 'oil-refinery', min_rate = 1 / 40 / 60, distance_factor = 1 / 40 / 60 / 512}
        },
        weight = 1
    }
}

local factory_weights = ob.prepare_weighted_loot(factory_loot)

local factory_callback = {
    callback = ob.magic_item_crafting_callback_weighted,
    data = {
        loot = factory_loot,
        weights = factory_weights
    }
}

local wall_chests = require 'map_gen.maps.crash_site.outpost_data.mini_wall_chests'
local turret = require 'map_gen.maps.crash_site.outpost_data.mini_gun_turret'

wall_chests = ob.extend_walls(wall_chests, {loot = {callback = loot_callback}})
turret = ob.extend_1_way(turret, {fallback = wall_chests, max_count = 2})

local blank = require 'map_gen.maps.crash_site.outpost_data.mini_blank'
local base_factory = require 'map_gen.maps.crash_site.outpost_data.mini_factory'
local gun_turret_block = require 'map_gen.maps.crash_site.outpost_data.mini_gun_turret_block'

local factory = ob.extend_1_way(base_factory, {factory = factory_callback, fallback = blank})
local gun = ob.extend_1_way(gun_turret_block, {fallback = factory})

return {
    settings = {
        part_size = 3,
        blocks = 4,
        variance = 3,
        min_step = 1,
        max_level = 2
    },
    walls = {
        turret,
        wall_chests
    },
    bases = {{factory, gun}}
}
