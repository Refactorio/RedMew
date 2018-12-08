-- luacheck: ignore pollution enemy_evolution enemy_expansion
local b = require 'map_gen.shared.builders'
local Event = require 'utils.event'
global.map.terraforming.creep_retraction_tiles = { 'sand-1' }
require 'map_gen.misc.nightfall' -- forces idle biters to attack at night
require 'map_gen.misc.terraforming' -- prevents players from building on non-terraformed tiles
local DayNight = require 'map_gen.misc.day_night'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Terraform Venus')
ScenarioInfo.set_map_description('After a long journey you have reached Venus. Your mission is simple, turn this hostile environment into one where humans can thrive')
ScenarioInfo.set_map_extra_info(
    '- Venus is an endless desert spotted with tiny oases\n' ..
    '- The atmosphere is toxic and you are not equipped to deal with it\n' ..
    '- While unsure the exact effects the atmosphere will have, you should be cautios of it\n' ..
    '- As you spread breathable atmosphere the ground will change to show where you can breathe\n' ..
    '- The days seem endless, but when the sun begins setting night is upon us immediately.\n' ..
    '- The biters here are numerous and seem especially aggressive during the short nights\n' ..
    '- Technology seems to take 6 times longer than usual'
)

local function value(base, mult)
    return function(x, y)
        return mult * (math.abs(x) + math.abs(y)) + base
    end
end

local function no_resources(_, _, world, tile)
    for _, e in ipairs(
        world.surface.find_entities_filtered(
            {type = 'resource', area = {{world.x, world.y}, {world.x + 1, world.y + 1}}}
        )
    ) do
        e.destroy()
    end
    for _, e in ipairs(
        world.surface.find_entities_filtered(
            -- all tree types
            {type = 'tree', area = {{world.x, world.y}, {world.x + 1, world.y + 1}}}
        )
    ) do
        e.destroy()
    end
    for _, e in ipairs(
        world.surface.find_entities_filtered(
            -- all rock types
            {type = 'simple-entity', area = {{world.x, world.y}, {world.x + 1, world.y + 1}}}
        )
    ) do
        e.destroy()
    end

    return tile
end

local function no_trees(_, _, world, tile)
    for _, e in ipairs(
        world.surface.find_entities_filtered({type = 'tree', area = {{world.x, world.y}, {world.x + 1, world.y + 1}}})
    ) do
        e.destroy()
    end

    return tile
end

-- create a square on which to place each ore
local square = b.rectangle(12, 12)
square = b.change_tile(square, true, 'lab-dark-2')

-- set the ore weights and sizes
local iron = b.resource(b.rectangle(12, 12), 'iron-ore', value(200, 1))
local copper = b.resource(b.rectangle(12, 12), 'copper-ore', value(150, 0.8))
local stone = b.resource(b.rectangle(12, 12), 'stone', value(100, .5))
local coal = b.resource(b.rectangle(12, 12), 'coal', value(100, 0.6))
local tree = b.entity(b.throttle_world_xy(b.full_shape, 1, 2, 1, 2), 'dead-tree-desert')

-- place each ore on the square
local iron_sq = b.apply_entity(square, iron)
local copper_sq = b.apply_entity(square, copper)
local stone_sq = b.apply_entity(square, stone)
local coal_sq = b.apply_entity(square, coal)
local tree_sq = b.apply_entity(square, tree)

-- create starting water square and change the type to water
local water_start =
    b.any {
    b.rectangle(12, 12)
}
water_start = b.change_tile(water_start, true, 'water')

-- create the large safe square
local safe_square = b.rectangle(80, 80)
safe_square = b.change_tile(safe_square, true, 'lab-dark-2')

-- create the start area using the ore, water and safe squares
local ore_distance = 24
local start_area =
    b.any {
    b.translate(iron_sq, -ore_distance, -ore_distance),
    b.translate(copper_sq, -ore_distance, ore_distance),
    b.translate(stone_sq, ore_distance, -ore_distance),
    b.translate(coal_sq, ore_distance, ore_distance),
    b.translate(tree_sq, ore_distance, 0),
    b.translate(tree_sq, 0, ore_distance),
    b.translate(tree_sq, 0, -ore_distance),
    b.translate(tree_sq, -ore_distance, 0),
    water_start,
    safe_square
}

start_area = b.apply_effect(start_area, no_resources)

local map = b.any {start_area, b.full_shape}
map = b.change_map_gen_collision_tile(map, 'ground-tile', 'sand-1')
map = b.translate(map, 6, -10) -- translate the whole map away, otherwise we'll spawn in the water
map = b.apply_effect(map, no_trees)

--- Sets the map parameters once the game begins and we have a surface to act on
local function world_settings()
    local surface = game.surfaces.nauvis
    local player_force = game.forces.player

    -- 20 minute cycle, 14m of full light, 1m light to dark, 4m full dark, 1m dark to light
    local day_night_cycle = {
        ['ticks_per_day'] = 72000,
        ['dusk'] = 0.625,
        ['evening'] = 0.775,
        ['morning'] = 0.925,
        ['dawn'] = 0.975
    }

    DayNight.set_cycle(day_night_cycle, surface)
    player_force.recipes['medium-electric-pole'].enabled = true
    player_force.technologies['steel-plate'].enabled = false
    player_force.technologies['artillery-shell-range-1'].enabled = false
    game.difficulty_settings.technology_price_multiplier = 1

    local map_settings = game.map_settings
    local pollution = map_settings.pollution
    local p = {
        enabled = true,
        diffusion_ratio = 0.01,
        min_to_diffuse = 30,
        ageing = 1,
        expected_max_per_chunk = 7000,
        min_to_show_per_chunk = 700,
        min_pollution_to_damage_trees = 3500,
        pollution_with_max_forest_damage = 10000,
        pollution_per_tree_damage = 2000,
        pollution_restored_per_tree_damage = 500,
        max_pollution_to_restore_trees = 1000
    }
    pollution = p
    local enemy_evolution = map_settings.enemy_evolution
    local e_ev = {
        enabled = true,
        time_factor = 0.00004,
        destroy_factor = 0.002,
        pollution_factor = 0.000045
    }
    enemy_evolution = e_ev
    local enemy_expansion = map_settings.enemy_expansion
    local e_ex = {
        enabled = true,
        max_expansion_distance = 10,
        friendly_base_influence_radius = 2,
        enemy_building_influence_radius = 2,
        building_coefficient = 0.1,
        other_base_coefficient = 2.0,
        neighbouring_chunk_coefficient = 0.5,
        neighbouring_base_chunk_coefficient = 0.4,
        max_colliding_tiles_coefficient = 0.9,
        settler_group_min_size = 2,
        settler_group_max_size = 30,
        min_expansion_cooldown = 1 * 3600,
        max_expansion_cooldown = 15 * 3600
    }
    enemy_expansion = e_ex

    surface.map_gen_settings = {
        terrain_segmentation = 'very-low', -- water frequency
        water = 'very-low', -- water size
        autoplace_controls = {
            stone = {frequency = 'normal', size = 'high', richness = 'low'},
            coal = {frequency = 'normal', size = 'high', richness = 'normal'},
            ['copper-ore'] = {frequency = 'normal', size = 'high', richness = 'low'},
            ['iron-ore'] = {frequency = 'normal', size = 'high', richness = 'normal'},
            ['uranium-ore'] = {frequency = 'normal', size = 'normal', richness = 'normal'},
            ['crude-oil'] = {frequency = 'normal', size = 'normal', richness = 'normal'},
            trees = {frequency = 'normal', size = 'none', richness = 'normal'},
            ['enemy-base'] = {frequency = 'very-high', size = 'very-high', richness = 'very-high'},
            grass = {frequency = 'normal', size = 'none', richness = 'normal'},
            desert = {frequency = 'normal', size = 'none', richness = 'normal'},
            dirt = {frequency = 'normal', size = 'none', richness = 'normal'},
            sand = {frequency = 'normal', size = 'normal', richness = 'normal'}
        },
        cliff_settings = {
            name = 'cliff',
            cliff_elevation_0 = 10,
            cliff_elevation_interval = 10
        },
        width = 0,
        height = 0,
        starting_area = 'very-low',
        peaceful_mode = false,
        seed = nil
    }
end
Event.on_init(world_settings)

return map
