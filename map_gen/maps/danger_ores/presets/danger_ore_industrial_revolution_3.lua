local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'
local Event = require 'utils.event'
local b = require 'map_gen.shared.builders'
local Config = require 'config'

local ScenarioInfo = require 'features.gui.info'
ScenarioInfo.set_map_name('Danger Ores x Industrial Revolution 3')
ScenarioInfo.set_map_description([[
Clear the ore to expand the base,
focus mining efforts on specific sectors to ensure
proper material ratios, expand the map with pollution!
]])
ScenarioInfo.add_map_extra_info([[
This map is split in 6 sectors. Each sector has a main resource. Gas fissures are scattered across the map.

 [item=transport-belt] [item=fast-transport-belt] [item=express-transport-belt] [item=underground-belt] [item=fast-underground-belt] [item=express-underground-belt]
 [item=small-electric-pole] [item=medium-electric-pole] [item=big-electric-pole] [item=substation] [item=small-bronze-pole] [item=small-iron-pole] [item=big-wooden-pole]
 [item=electric-mining-drill] [item=burner-mining-drill] [item=pumpjack] [item=steam-drill] [item=chrome-drill] [item=copper-derrick] [item=steel-derrick]
 [item=copper-pipe] [item=copper-pipe-to-ground] [item=copper-pipe-to-ground-short] [item=steam-pipe] [item=steam-pipe-to-ground] [item=steam-pipe-to-ground-short] [item=pipe] [item=pipe-to-ground] [item=pipe-to-ground-short] [item=air-pipe] [item=air-pipe-to-ground] [item=air-pipe-to-ground-short]
 [item=car] [item=tank] [item=spidertron] [item=monowheel] [item=heavy-roller] [item=heavy-picket]
 [item=rail-signal] [item=rail-chain-signal] [item=rail] [item=train-stop] [item=locomotive] [item=cargo-wagon] [item=fluid-wagon] [item=artillery-wagon]

The map size is restricted to the pollution generated. A significant amount of
pollution must affect a section of the map before it is revealed. Pollution
does not affect biter evolution.
]])

ScenarioInfo.set_new_info([[
2023-10-24:
 - Added IR3 preset
]])

ScenarioInfo.add_extra_rule({'info.rules_text_danger_ore'})

global.config.redmew_qol.loaders = false

local map = require 'map_gen.maps.danger_ores.modules.map'
local main_ores_config = require 'map_gen.maps.danger_ores.config.ir3_ores'
local resource_patches = require 'map_gen.maps.danger_ores.modules.resource_patches'
local resource_patches_config = require 'map_gen.maps.danger_ores.config.ir3_resource_patches'
local water = require 'map_gen.maps.danger_ores.modules.water'
local trees = require 'map_gen.maps.danger_ores.modules.trees'
local enemy = require 'map_gen.maps.danger_ores.modules.enemy'
-- local dense_patches = require 'map_gen.maps.danger_ores.modules.dense_patches'

local banned_entities = require 'map_gen.maps.danger_ores.modules.banned_entities'
local allowed_entities = require 'map_gen.maps.danger_ores.config.ir3_allowed_entities'
banned_entities(allowed_entities)

local ores_names = {
    -- point patches
    'crude-oil',
    'dirty-steam-fissure',
    'natural-gas-fissure',
    'steam-fissure',
    'sulphur-gas-fissure',
    -- ore patches
    'coal',
    'copper-ore',
    'iron-ore',
    'stone',
    'uranium-ore',
    'gold-ore',
    'tin-ore',
}
local ore_oil_none = {}
for _, v in pairs(ores_names) do
    ore_oil_none[v] = {frequency = 1, richness = 1, size = 0}
end
ore_oil_none = {autoplace_controls = ore_oil_none}

RS.set_map_gen_settings({
    MGSP.grass_only,
    MGSP.enable_water,
    { terrain_segmentation = 'normal', water = 'normal' },
    MGSP.starting_area_very_low,
    ore_oil_none,
    MGSP.enemy_none,
    MGSP.cliff_none,
    MGSP.tree_none
})

Config.market.enabled = false
Config.player_rewards.enabled = false
Config.player_create.starting_items = {
    { count =   1, name = 'shotgun' },
    { count =   4, name = 'burner-mining-drill' },
    { count =   4, name = 'stone-furnace'},
    { count =  25, name = 'copper-rivet' },
    { count =  25, name = 'copper-rod' },
    { count =  25, name = 'tin-gear-wheel' },
    { count =  25, name = 'tin-plate' },
    { count =  25, name = 'tin-rod' },
    { count =  50, name = 'copper-gear-wheel' },
    { count =  50, name = 'copper-plate' },
    { count =  50, name = 'shotgun-shell' },
    { count = 100, name = 'tin-scrap' },
    { count = 150, name = 'copper-scrap' },
}
Config.dump_offline_inventories = {
    enabled = true,
    offline_timout_mins = 30 -- time after which a player logs off that their inventory is provided to the team
}
Config.paint.enabled = false

if script.active_mods['early_construction'] then
    table.insert(Config.player_create.starting_items, { count =   1, name = 'early-construction-light-armor' })
    table.insert(Config.player_create.starting_items, { count =   1, name = 'early-construction-equipment' })
    table.insert(Config.player_create.starting_items, { count = 100, name = 'early-construction-robot' })
end

Event.on_init(function()
    game.draw_resource_selection = false

    game.forces.player.technologies['mining-productivity-1'].enabled = false
    game.forces.player.technologies['mining-productivity-2'].enabled = false
    game.forces.player.technologies['mining-productivity-3'].enabled = false
    game.forces.player.technologies['mining-productivity-4'].enabled = false

    game.forces.player.manual_mining_speed_modifier = 1

    game.difficulty_settings.technology_price_multiplier = game.difficulty_settings.technology_price_multiplier * 5

    game.map_settings.enemy_evolution.time_factor = 0.000007 -- default 0.000004
    game.map_settings.enemy_evolution.destroy_factor = 0.000010 -- default 0.002
    game.map_settings.enemy_evolution.pollution_factor = 0.000000 -- Pollution has no affect on evolution default 0.0000009

    RS.get_surface().always_day = false
    RS.get_surface().peaceful_mode = true
end)

local terraforming = require 'map_gen.maps.danger_ores.modules.terraforming'
terraforming({start_size = 10 * 32, min_pollution = 400, max_pollution = 16000, pollution_increment = 4})

local rocket_launched = require 'map_gen.maps.danger_ores.modules.rocket_launched_simple'
rocket_launched({win_satellite_count = 100})

local restart_command = require 'map_gen.maps.danger_ores.modules.restart_command'
restart_command({scenario_name = 'danger-ore-industrial-revolution-3'})

local container_dump = require 'map_gen.maps.danger_ores.modules.container_dump'
container_dump({entity_name = 'coal'})

local concrete_on_landfill = require 'map_gen.maps.danger_ores.modules.concrete_on_landfill'
concrete_on_landfill({tile = 'blue-refined-concrete'})

require 'map_gen.maps.danger_ores.modules.biter_drops'

require 'map_gen.maps.danger_ores.modules.map_poll'

local config = {
    spawn_shape = b.circle(40),
    start_ore_shape = b.circle(48),
    no_resource_patch_shape = b.circle(80),
    main_ores = main_ores_config,
    main_ores_shuffle_order = true,
    resource_patches = resource_patches,
    resource_patches_config = resource_patches_config,
    water = water,
    water_scale = 1 / 96,
    water_threshold = 0.5,
    deepwater_threshold = 0.55,
    no_water_shape = b.circle(102),
    trees = trees,
    trees_scale = 1 / 64,
    trees_threshold = 0.4,
    trees_chance = 0.875,
    enemy = enemy,
    enemy_factor = 10 / (768 * 32),
    enemy_max_chance = 1 / 6,
    enemy_scale_factor = 32,
    fish_spawn_rate = 0.025,
    dense_patches_scale = 1 / 48,
    dense_patches_threshold = 0.5,
    dense_patches_multiplier = 50
}

return map(config)
