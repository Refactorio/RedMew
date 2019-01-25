local b = require 'map_gen.shared.builders'
local Event = require 'utils.event'
global.map.terraforming.creep_retraction_tiles = {'sand-1'}
require 'map_gen.misc.nightfall' -- forces idle biters to attack at night
require 'map_gen.misc.terraforming' -- prevents players from building on non-terraformed tiles
local DayNight = require 'map_gen.misc.day_night'
local ScenarioInfo = require 'features.gui.info'
local RS = require 'map_gen.shared.redmew_surface'

-- Info and world settings

ScenarioInfo.set_map_name('Terraform Venus')
ScenarioInfo.set_map_description('After a long journey you have reached Venus. Your mission is simple, turn this hostile environment into one where humans can thrive')
ScenarioInfo.add_map_extra_info(
    '- Venus is an endless desert spotted with tiny oases\n' ..
    '- The atmosphere is toxic and you are not equipped to deal with it\n' ..
    '- While unsure the exact effects the atmosphere will have, you should be cautios of it\n' ..
    '- As you spread breathable atmosphere the ground will change to show where you can breathe\n' ..
    '- The days seem endless, but when the sun begins setting night is upon us immediately.\n' ..
    '- The biters here are numerous and seem especially aggressive during the short nights'
)

local MGSP = require 'resources.map_gen_settings' -- map gen settings presets
local DSP = require 'resources.difficulty_settings' -- difficulty settings presets
local MSP = require 'resources.map_settings' -- map settings presets

RS.set_map_gen_settings({MGSP.tree_none, MGSP.enemy_very_high, MGSP.water_very_low,MGSP.cliff_normal, MGSP.starting_area_very_low, MGSP.sand_only})
RS.set_difficulty_settings({DSP.tech_x2})
RS.set_map_settings({MSP.pollution_hard_to_spread, MSP.enemy_evolution_punishes_pollution, MSP.enemy_expansion_frequency_x4, MSP.enemy_expansion_aggressive})

-- 20 minute cycle, 14m of full light, 1m light to dark, 4m full dark, 1m dark to light
DayNight.day_night_cycle = {
    ['ticks_per_day'] = 72000,
    ['dusk'] = 0.625,
    ['evening'] = 0.775,
    ['morning'] = 0.925,
    ['dawn'] = 0.975
}

--- Sets recipes and techs to be enabled/disabled
local function init()
    local player_force = game.forces.player
    player_force.recipes['medium-electric-pole'].enabled = true
    player_force.recipes['steel-plate'].enabled = true
    player_force.technologies['artillery-shell-range-1'].enabled = false
end

-- Map Generation

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

Event.on_init(init)

return map
