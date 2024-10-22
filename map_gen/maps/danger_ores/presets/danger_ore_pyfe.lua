local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'
local Event = require 'utils.event'
local b = require 'map_gen.shared.builders'
local Config = require 'config'

local ScenarioInfo = require 'features.gui.info'
ScenarioInfo.set_map_name('Danger Ores x Pyanodon Fusion Energy')
ScenarioInfo.set_map_description([[
Clear the ore to expand the base,
focus mining efforts on specific sectors to ensure
proper material ratios, expand the map with pollution!
]])
ScenarioInfo.add_map_extra_info([[
This map is split in 6 sectors. Each sector has a main resource.

You may not build the factory on ore patches. Exceptions:
 [item=transport-belt] [item=fast-transport-belt] [item=express-transport-belt] [item=underground-belt] [item=fast-underground-belt] [item=express-underground-belt]  [item=splitter] [item=fast-splitter] [item=express-splitter]
 [item=pipe] [item=pipe-to-ground] [item=small-electric-pole] [item=medium-electric-pole] [item=big-electric-pole] [item=substation]
 [item=electric-mining-drill] [item=burner-mining-drill] [item=pumpjack] [item=mo-mine] [item=diamond-mine] [item=regolite-mine] [item=borax-mine] [item=niobium-mine] [item=car] [item=tank] [item=spidertron]
 [item=burner-inserter] [item=inserter] [item=long-handed-inserter] [item=fast-inserter] [item=stack-inserter]
 [item=rail] [item=rail-chain-signal] [item=train-stop] [item=locomotive] [item=cargo-wagon] [item=fluid-wagon] [item=artillery-wagon]
 [item=mk02-locomotive] [item=mk02-wagon] [item=mk02-fluid-wagon] [item=niobium-pipe] [item=niobium-pipe-to-ground] [item=pipe] [item=pipe-to-ground]

The map size is restricted to the pollution generated. A significant amount of
pollution must affect a section of the map before it is revealed. Pollution
does not affect biter evolution.
]])

ScenarioInfo.set_new_info([[
2023-10-24:
 - Added PyFE preset
]])

ScenarioInfo.add_extra_rule({'info.rules_text_danger_ore'})

storage.config.redmew_qol.loaders = false

local map = require 'map_gen.maps.danger_ores.modules.map'
local main_ores_config = require 'map_gen.maps.danger_ores.config.pyfe_ores'
local ore_builder = require 'map_gen.maps.danger_ores.modules.ore_builder_without_gaps'
local resource_patches = require 'map_gen.maps.danger_ores.modules.resource_patches'
local resource_patches_config = require 'map_gen.maps.danger_ores.config.pyfe_resource_patches'
local trees = require 'map_gen.maps.danger_ores.modules.trees'

local banned_entities = require 'map_gen.maps.danger_ores.modules.banned_entities'
local allowed_entities = require 'map_gen.maps.danger_ores.config.pyanodon_allowed_entities'
banned_entities(allowed_entities)

local ores_names = {
    -- point patches
    'crude-oil',
    'regolites',
    'volcanic-pipe',
    -- ore patches
    'coal',
    'stone',
    'copper-ore',
    'uranium-ore',
    'iron-ore',
    'borax',
    'molybdenum-ore',
    'niobium',
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
    { count = 10, name = 'burner-mining-drill' },
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

    game.map_settings.pollution.diffusion_ratio = 0.01
    game.map_settings.pollution.min_to_diffuse = 300

    game.map_settings.enemy_evolution.time_factor = 0.000007 -- default 0.000004
    game.map_settings.enemy_evolution.destroy_factor = 0.000010 -- default 0.002
    game.map_settings.enemy_evolution.pollution_factor = 0.000000 -- Pollution has no affect on evolution default 0.0000009

    RS.get_surface().always_day = false
    RS.get_surface().peaceful_mode = true
end)

local terraforming = require 'map_gen.maps.danger_ores.modules.terraforming'
terraforming({start_size = 12 * 32, min_pollution = 300, max_pollution = 16000, pollution_increment = 2})

local rocket_launched = require 'map_gen.maps.danger_ores.modules.rocket_launched_pyanodon'
rocket_launched()

local restart_command = require 'map_gen.maps.danger_ores.modules.restart_command'
restart_command({scenario_name = 'danger-ore-pyfe'})

local container_dump = require 'map_gen.maps.danger_ores.modules.container_dump'
container_dump({entity_name = 'coal'})

local tech_scaling = require 'map_gen.maps.danger_ores.modules.tech_scaling'
tech_scaling({ effects = {
    ['automation-science-pack'] = 1.00,
    ['logistic-science-pack']   = 0.75,
    ['chemical-science-pack']   = 0.50,
    ['production-science-pack'] = 0.25,
    ['utility-sciemce-pack']    = 0.20,
    ['space-science-pack']      = 0.10,
}})
-- local concrete_on_landfill = require 'map_gen.maps.danger_ores.modules.concrete_on_landfill'
-- concrete_on_landfill({tile = 'blue-refined-concrete'})

require 'map_gen.maps.danger_ores.modules.biter_drops'
require 'features.landfill_remover'
require 'map_gen.maps.danger_ores.modules.map_poll'

local config = {
    spawn_shape = b.rectangle(100),
    start_ore_shape = b.empty_shape,
    spawn_tile = 'landfill',
    ore_builder = ore_builder,
    main_ores = main_ores_config,
    main_ores_shuffle_order = true,
    resource_patches = resource_patches,
    resource_patches_config = resource_patches_config,
    water_scale = 1 / 96,
    water_threshold = 0.4,
    deepwater_threshold = 0.45,
    trees = trees,
    trees_scale = 1 / 64,
    trees_threshold = 0.4,
    trees_chance = 0.875,
    enemy = nil,
    enemy_factor = 10 / (768 * 32),
    enemy_max_chance = 1 / 6,
    enemy_scale_factor = 32,
    fish_spawn_rate = 0.025,
    dense_patches_scale = 1 / 48,
    dense_patches_threshold = 0.5,
    dense_patches_multiplier = 50
}

return map(config)
