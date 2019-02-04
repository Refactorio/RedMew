local ob = require 'map_gen.maps.crash_site.outpost_builder'
local Token = require 'utils.token'

local loot = {
    {weight = 5},
    {stack = {name = 'coin', count = 100, distance_factor = 1 / 8}, weight = 3},
    {stack = {name = 'raw-fish', count = 50, distance_factor = 1 / 16}, weight = 1},
    {stack = {name = 'combat-shotgun', count = 3, distance_factor = 1 / 128}, weight = 1},
    {stack = {name = 'shotgun-shell', count = 100, distance_factor = 1 / 16}, weight = 1},
    {stack = {name = 'piercing-shotgun-shell', count = 50, distance_factor = 1 / 32}, weight = 1},
    {stack = {name = 'rocket-launcher', count = 3, distance_factor = 1 / 128}, weight = 1},
    {stack = {name = 'gun-turret', count = 15, distance_factor = 1 / 32}, weight = 1},
    {stack = {name = 'heavy-armor', count = 10, distance_factor = 1 / 64}, weight = 3}
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
            recipe = 'piercing-shotgun-shell',
            output = {item = 'piercing-shotgun-shell', min_rate = 0.75 / 8 / 60, distance_factor = 1 / 8 / 60 / 512}
        },
        weight = 5
    },
    {
        stack = {
            recipe = 'gun-turret',
            output = {item = 'gun-turret', min_rate = 0.5 / 15 / 60, distance_factor = 0.5 / 15 / 60 / 512}
        },
        weight = 5
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
