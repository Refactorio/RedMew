local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'
local Event = require 'utils.event'
local b = require 'map_gen.shared.builders'
local Config = require 'config'

local ScenarioInfo = require 'features.gui.info'
ScenarioInfo.set_map_name('Danger Ores x Exotic Industries Spiral')
ScenarioInfo.set_map_description([[
Clear the ore to expand the base,
focus mining efforts on specific sectors to ensure
proper material ratios, expand the map with pollution!
]])
ScenarioInfo.add_map_extra_info([[
This map is split in 3 sectors. Each sector has a main resource. Resource veins are scattered across the map.

You may not build the factory on ore patches. Exceptions:
 [item=transport-belt] [item=fast-transport-belt] [item=express-transport-belt] [item=ei_neo-belt] [item=underground-belt] [item=fast-underground-belt] [item=express-underground-belt] [item=ei_neo-underground-belt]
 [item=pipe] [item=pipe-to-ground] [item=ei_insulated-pipe] [item=ei_insulated-underground-pipe] [item=small-electric-pole] [item=medium-electric-pole] [item=big-electric-pole] [item=substation]
 [item=electric-mining-drill] [item=ei_advanced-electric-mining-drill] [item=ei_superior-electric-mining-drill] [item=ei_deep-drill] [item=ei_advanced-deep-drill] [item=burner-mining-drill] [item=pumpjack] [item=ei_steam-oil-pumpjack]
 [item=car] [item=tank] [item=spidertron]
 [item=rail] [item=rail-signal] [item=rail-chain-signal] [item=train-stop] [item=locomotive] [item=cargo-wagon] [item=fluid-wagon] [item=artillery-wagon] [item=ei_steam-basic-locomotive] [item=ei_steam-basic-wagon] [item=ei_steam-advanced-locomotive] [item=ei_steam-advanced-wagon] [item=ei_steam-advanced-fluid-wagon]

The map size is restricted to the pollution generated. A significant amount of
pollution must affect a section of the map before it is revealed. Pollution
does not affect biter evolution.
]])

ScenarioInfo.set_new_info([[
2023-10-26:
 - Added EI spiral preset
]])

ScenarioInfo.add_extra_rule({'info.rules_text_danger_ore'})

global.config.redmew_qol.loaders = false

local map = require 'map_gen.maps.danger_ores.modules.map'
local main_ores_config = require 'map_gen.maps.danger_ores.config.vanilla_ores'
local main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_spiral'
local resource_patches = require 'map_gen.maps.danger_ores.modules.resource_patches'
local resource_patches_config = require 'map_gen.maps.danger_ores.config.exotic_industries_resource_patches'
local water = require 'map_gen.maps.danger_ores.modules.water'
local trees = require 'map_gen.maps.danger_ores.modules.trees'
local enemy = require 'map_gen.maps.danger_ores.modules.enemy'

local banned_entities = require 'map_gen.maps.danger_ores.modules.banned_entities'
local allowed_entities = require 'map_gen.maps.danger_ores.config.exotic_industries_allowed_entities'
banned_entities(allowed_entities)

local ores_names = {
    -- point patches
    'crude-oil',
    'ei_coal-patch',
    'ei_copper-patch',
    'ei_gold-patch',
    'ei_iron-patch',
    'ei_lead-patch',
    'ei_neodym-patch',
    'ei_sulfur-patch',
    'ei_uranium-patch',
    -- ore patches
    'coal',
    'copper-ore',
    'iron-ore',
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
    { count =  1, name = 'stone-furnace'},
    { count =  2, name = 'burner-mining-drill' },
    { count = 50, name = 'wood' },
}
Config.dump_offline_inventories = {
    enabled = true,
    offline_timeout_mins = 30, -- time after which a player logs off that their inventory is provided to the team
    startup_gear_drop_hours = 24, -- time after which players will keep at least their armor when disconnecting
}
Config.paint.enabled = false
Config.permissions.presets.no_blueprints = true

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

    game.map_settings.enemy_evolution.time_factor = 0.000007 -- default 0.000004
    game.map_settings.enemy_evolution.destroy_factor = 0.000010 -- default 0.002
    game.map_settings.enemy_evolution.pollution_factor = 0.000000 -- Pollution has no affect on evolution default 0.0000009

    RS.get_surface().always_day = true
    RS.get_surface().peaceful_mode = true
end)

local terraforming = require 'map_gen.maps.danger_ores.modules.terraforming'
terraforming({start_size = 10 * 32, min_pollution = 300, max_pollution = 15000, pollution_increment = 3})

local rocket_launched = require 'map_gen.maps.danger_ores.modules.rocket_launched_exotic_industries'
rocket_launched()

local restart_command = require 'map_gen.maps.danger_ores.modules.restart_command'
restart_command({scenario_name = 'danger-ore-exotic-industries-spiral'})

local container_dump = require 'map_gen.maps.danger_ores.modules.container_dump'
container_dump({entity_name = 'coal'})

local concrete_on_landfill = require 'map_gen.maps.danger_ores.modules.concrete_on_landfill'
concrete_on_landfill({tile = 'blue-refined-concrete'})

require 'map_gen.maps.danger_ores.modules.biter_drops_exotic_industries'

require 'map_gen.maps.danger_ores.modules.map_poll'

local config = {
    spawn_shape = b.circle(64),
    start_ore_shape = b.circle(68),
    --no_resource_patch_shape = b.circle(80),
    spawn_tile = 'landfill',
    main_ores = main_ores_config,
    main_ores_builder = main_ores_builder,
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
