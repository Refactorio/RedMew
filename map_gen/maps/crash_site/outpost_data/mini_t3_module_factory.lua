local ob = require 'map_gen.maps.crash_site.outpost_builder'
local Token = require 'utils.token'

local loot = {
    {weight = 10},
    {stack = {name = 'coin', count = 50, distance_factor = 1 / 20}, weight = 5},
    {stack = {name = 'effectivity-module-3', count = 4, distance_factor = 1 / 64}, weight = 5},
    {stack = {name = 'speed-module-3', count = 2, distance_factor = 1 / 64}, weight = 5},
    {stack = {name = 'productivity-module-3', count = 2, distance_factor = 1 / 64}, weight = 5}
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
            recipe = 'effectivity-module-3',
            output = {item = 'effectivity-module-3', min_rate = 0.5 / 60 / 60, distance_factor = 0.5 / 60 / 60 / 512}
        },
        weight = 5
    },
    {
        stack = {
            recipe = 'speed-module-3',
            output = {item = 'speed-module-3', min_rate = 0.5 / 60 / 60, distance_factor = 0.5 / 60 / 60 / 512}
        },
        weight = 5
    },
    {
        stack = {
            recipe = 'productivity-module-3',
            output = {item = 'productivity-module-3', min_rate = 0.5 / 60 / 60, distance_factor = 0.5 / 60 / 60 / 512}
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

local wall_chests = require 'map_gen.maps.crash_site.outpost_data.mini_hazard_wall_chests'
local turret = require 'map_gen.maps.crash_site.outpost_data.mini_laser_turret'

wall_chests = ob.extend_walls(wall_chests, {loot = {callback = loot_callback}})
turret = ob.extend_walls(turret, {fallback = wall_chests, max_count = 2})

local blank = require 'map_gen.maps.crash_site.outpost_data.mini_blank'
local base_factory = require 'map_gen.maps.crash_site.outpost_data.mini_factory'
local laser_turret_block = require 'map_gen.maps.crash_site.outpost_data.mini_laser_turret_block'

local factory = ob.extend_1_way(base_factory, {factory = factory_callback, fallback = blank})
local gun = ob.extend_1_way(laser_turret_block, {fallback = factory})

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
