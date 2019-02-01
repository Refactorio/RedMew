local ob = require 'map_gen.maps.crash_site.outpost_builder'
local Token = require 'utils.token'

local loot = {
    {weight = 5},
    {stack = {name = 'coin', count = 150, distance_factor = 1 / 8}, weight = 3},
    {stack = {name = 'raw-fish', count = 50, distance_factor = 1 / 16}, weight = 1},
    {stack = {name = 'piercing-shotgun-shell', count = 250, distance_factor = 1 / 16}, weight = 1},
    {stack = {name = 'flamethrower', count = 3, distance_factor = 1 / 128}, weight = 1},
    {stack = {name = 'flamethrower-ammo', count = 75, distance_factor = 1 / 16}, weight = 1},
    {stack = {name = 'rocket', count = 50, distance_factor = 1 / 16}, weight = 1},
    {stack = {name = 'explosive-rocket', count = 35, distance_factor = 1 / 16}, weight = 1},
    {stack = {name = 'gun-turret', count = 25, distance_factor = 1 / 32}, weight = 1},
    {stack = {name = 'flamethrower-turret', count = 5, distance_factor = 1 / 64}, weight = 1},
    {stack = {name = 'cluster-grenade', count = 25, distance_factor = 1 / 32}, weight = 1},
    {stack = {name = 'modular-armor', count = 4, distance_factor = 1 / 128}, weight = 2},
    {stack = {name = 'solar-panel-equipment', count = 10, distance_factor = 1 / 32}, weight = 1},
    {stack = {name = 'battery-equipment', count = 8, distance_factor = 1 / 128}, weight = 1},
    {stack = {name = 'energy-shield-equipment', count = 8, distance_factor = 1 / 128}, weight = 1}
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
            recipe = 'laser-turret',
            output = {item = 'laser-turret', min_rate = 1 / 20 / 60, distance_factor = 1 / 20 / 60 / 512}
        },
        weight = 1
    },
    {
        stack = {
            recipe = 'flamethrower-turret',
            output = {item = 'flamethrower-turret', min_rate = 1 / 20 / 60, distance_factor = 1 / 20 / 60 / 512}
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
turret =
    ob.extend_walls(
    turret,
    {
        fallback = wall_chests,
        max_count = 2,
        turret = {callback = ob.refill_turret_callback, data = ob.uranium_rounds_magazine_ammo}
    }
)

local blank = require 'map_gen.maps.crash_site.outpost_data.mini_blank'
local base_factory = require 'map_gen.maps.crash_site.outpost_data.mini_factory'
local gun_turret_block = require 'map_gen.maps.crash_site.outpost_data.mini_gun_turret_block'

local factory = ob.extend_1_way(base_factory, {factory = factory_callback, fallback = blank})
local gun =
    ob.extend_1_way(
    gun_turret_block,
    {fallback = factory, turret = {callback = ob.refill_turret_callback, data = ob.uranium_rounds_magazine_ammo}}
)

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
