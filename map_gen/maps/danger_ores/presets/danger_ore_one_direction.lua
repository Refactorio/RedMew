local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'
local Event = require 'utils.event'
local b = require 'map_gen.shared.builders'
local Config = require 'config'

local ScenarioInfo = require 'features.gui.info'
ScenarioInfo.set_map_name('Danger Ore One Direction')
ScenarioInfo.set_map_description([[
Clear the ore to expand the base,
focus mining efforts on specific sectors to ensure
proper material ratios, expand the map with pollution!
]])
ScenarioInfo.add_map_extra_info([[
This map is split in three sectors [item=iron-ore] [item=copper-ore] [item=coal].
Each sector has a main resource and the other resources at a lower ratio.

You may not build the factory on ore patches. Exceptions:
 [item=burner-mining-drill] [item=electric-mining-drill] [item=pumpjack] [item=small-electric-pole] [item=medium-electric-pole] [item=big-electric-pole] [item=substation] [item=car] [item=tank] [item=spidertron] [item=locomotive] [item=cargo-wagon] [item=fluid-wagon] [item=artillery-wagon]
 [item=transport-belt] [item=fast-transport-belt] [item=express-transport-belt]  [item=underground-belt] [item=fast-underground-belt] [item=express-underground-belt] [item=rail] [item=rail-signal] [item=rail-chain-signal] [item=train-stop]

The map size is restricted to the pollution generated. A significant amount of
pollution must affect a section of the map before it is revealed. Pollution
does not affect biter evolution.]])

ScenarioInfo.set_new_info([[
2019-04-24:
 - Stone ore density reduced by 1/2
 - Ore quadrants randomized
 - Increased time factor of biter evolution from 5 to 7
 - Added win conditions (+5% evolution every 5 rockets until 100%, +100 rockets until biters are wiped)

2019-03-30:
 - Uranium ore patch threshold increased slightly
 - Bug fix: Cars and tanks can now be placed onto ore!
 - Starting minimum pollution to expand map set to 650
    View current pollution via Debug Settings [F4] show-pollution-values,
    then open map and turn on pollution via the red box.
 - Starting water at spawn increased from radius 8 to radius 16 circle.

2019-03-27:
 - Ore arranged into quadrants to allow for more controlled resource gathering.

2020-09-02:
 - Destroyed chests dump their content as coal ore.

2020-12-28:
 - Changed win condition. First satellite kills all biters, launch 500 to win the map.

2021-04-06:
 - Rail signals and train stations now allowed on ore.
]])

ScenarioInfo.add_extra_rule({'info.rules_text_danger_ore'})

local map = require 'map_gen.maps.danger_ores.modules.map'
local main_ores_config = require 'map_gen.maps.danger_ores.config.vanilla_ores_one_direction'
local resource_patches = require 'map_gen.maps.danger_ores.modules.resource_patches'
local resource_patches_config = require 'map_gen.maps.danger_ores.config.vanilla_resource_patches'
-- local water = require 'map_gen.maps.danger_ores.modules.water'
local trees = require 'map_gen.maps.danger_ores.modules.trees'
local enemy = require 'map_gen.maps.danger_ores.modules.enemy'
-- local dense_patches = require 'map_gen.maps.danger_ores.modules.dense_patches'

local banned_entities = require 'map_gen.maps.danger_ores.modules.banned_entities'
local allowed_entities = require 'map_gen.maps.danger_ores.config.vanilla_allowed_entities'
banned_entities(allowed_entities)

RS.set_map_gen_settings({
    MGSP.grass_only,
    MGSP.enable_water,
    {terrain_segmentation = 'normal', water = 'normal'},
    MGSP.starting_area_very_low,
    MGSP.ore_oil_none,
    MGSP.enemy_none,
    MGSP.cliff_none,
    MGSP.tree_none,
    {height = 32 * 3}
})

Config.market.enabled = false
Config.player_rewards.enabled = false
Config.player_create.starting_items = {}
Config.dump_offline_inventories = {
    enabled = true,
    offline_timeout_mins = 30 -- time after which a player logs off that their inventory is provided to the team
}
Config.paint.enabled = false

Event.on_init(function()
    game.draw_resource_selection = false
    game.forces.player.technologies['mining-productivity-1'].enabled = false
    game.forces.player.technologies['mining-productivity-2'].enabled = false
    game.forces.player.technologies['mining-productivity-3'].enabled = false
    game.forces.player.technologies['mining-productivity-4'].enabled = false

    game.difficulty_settings.technology_price_multiplier = 25
    game.forces.player.technologies.logistics.researched = true
    game.forces.player.technologies.automation.researched = true

    game.map_settings.enemy_evolution.time_factor = 0.000007 -- default 0.000004
    game.map_settings.enemy_evolution.destroy_factor = 0.000010 -- default 0.002
    game.map_settings.enemy_evolution.pollution_factor = 0.000000 -- Pollution has no affect on evolution default 0.0000009

    game.forces.player.manual_mining_speed_modifier = 1

    RS.get_surface().always_day = true
end)

local function terraforming_bounds(x, y)
    return x > -64 and y > -64 and y < 64
end

local terraforming = require 'map_gen.maps.danger_ores.modules.terraforming'
terraforming({
    start_size = 12 * 32,
    min_pollution = 200,
    max_pollution = 16000,
    pollution_increment = 4,
    bounds = terraforming_bounds
})

local rocket_launched = require 'map_gen.maps.danger_ores.modules.rocket_launched_simple'
rocket_launched({win_satellite_count = 250})

local restart_command = require 'map_gen.maps.danger_ores.modules.restart_command'
restart_command({scenario_name = 'danger-ore-one-direction'})

local container_dump = require 'map_gen.maps.danger_ores.modules.container_dump'
container_dump({entity_name = 'coal'})

local concrete_on_landfill = require 'map_gen.maps.danger_ores.modules.concrete_on_landfill'
concrete_on_landfill({tile = 'blue-refined-concrete'})

local main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_one_direction'

local function post_map_func(map_shape)
    local function map_bounds(x, y)
        return x > -44 and y > -48 and y < 48
    end

    local function water_bounds(x, y)
        return x > -46 and y > -50 and y < 50
    end

    local water_border = b.tile('water')
    water_border = b.choose(water_bounds, water_border, b.empty_shape)

    return b.choose(map_bounds, map_shape, water_border)
end

local config = {
    spawn_shape = b.rectangle(72),
    start_ore_shape = b.rectangle(88),
    post_map_func = post_map_func,
    main_ores_builder = main_ores_builder,
    no_resource_patch_shape = b.rectangle(160),
    main_ores = main_ores_config,
    main_ores_shuffle_order = true,
    -- main_ores_rotate = 30,
    resource_patches = resource_patches,
    resource_patches_config = resource_patches_config,
    -- water = water,
    water_scale = 1 / 96,
    water_threshold = 0.4,
    deepwater_threshold = 0.45,
    trees = trees,
    trees_scale = 1 / 64,
    trees_threshold = 0.3,
    trees_chance = 0.875,
    enemy = enemy,
    enemy_factor = 10 / (768 * 32),
    enemy_max_chance = 1 / 6,
    enemy_scale_factor = 32,
    fish_spawn_rate = 0.025,
    -- dense_patches = dense_patches,
    dense_patches_scale = 1 / 48,
    dense_patches_threshold = 0.55,
    dense_patches_multiplier = 25
}

return map(config)
