local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'
local Event = require 'utils.event'
local b = require 'map_gen.shared.builders'
local Config = require 'config'

local ScenarioInfo = require 'features.gui.info'
ScenarioInfo.set_map_name('Danger Ore Scrapworld')
ScenarioInfo.set_map_description([[
Clear the scrap to expand the base,
expand the map with pollution!
]])
ScenarioInfo.add_map_extra_info([[
This map is covered in [entity=scrap].
Mine it to make room for your factory.

You may not build the factory on ore patches. Exceptions:
 [item=burner-mining-drill] [item=electric-mining-drill] [item=pumpjack] [item=small-electric-pole] [item=medium-electric-pole] [item=big-electric-pole] [item=substation] [item=car] [item=tank] [item=spidertron] [item=locomotive] [item=cargo-wagon] [item=fluid-wagon] [item=artillery-wagon]
 [item=transport-belt] [item=fast-transport-belt] [item=express-transport-belt]  [item=underground-belt] [item=fast-underground-belt] [item=express-underground-belt] [item=rail] [item=rail-signal] [item=rail-chain-signal] [item=train-stop]


The map size is restricted to the pollution generated. A significant amount of
pollution must affect a section of the map before it is revealed. Pollution
does not affect biter evolution.
]])

ScenarioInfo.set_new_info([[
2024-02-24:
 - Added Scrap preset
]])

ScenarioInfo.add_extra_rule({'info.rules_text_danger_ore'})

storage.config.redmew_qol.loaders = false

local map = require 'map_gen.maps.danger_ores.modules.map'
local main_ores_config = require 'map_gen.maps.danger_ores.config.scrap'
local water = require 'map_gen.maps.danger_ores.modules.water'
local trees = require 'map_gen.maps.danger_ores.modules.trees'
local enemy = require 'map_gen.maps.danger_ores.modules.enemy'

local banned_entities = require 'map_gen.maps.danger_ores.modules.banned_entities'
local allowed_entities = require 'map_gen.maps.danger_ores.config.deadlock_beltboxes_allowed_entities'
banned_entities(allowed_entities)

local scrap_resources_control = MGSP.ore_oil_none
scrap_resources_control.autoplace_controls['scrap'] = {frequency = 1, richness = 1, size = 0}

RS.set_map_gen_settings({
    MGSP.dirt_only,
    MGSP.enable_water,
    {terrain_segmentation = 'normal', water = 'normal'},
    MGSP.starting_area_very_low,
    scrap_resources_control,
    MGSP.enemy_none,
    MGSP.cliff_none,
})

-- Config.lazy_bastard.enabled = true
Config.market.enabled = false
Config.player_rewards.enabled = false
Config.player_create.starting_items = {
    { count =  2, name = 'burner-mining-drill' },
    { count =  5, name = 'iron-chest' },
    { count = 50, name = 'wood' },
    { count =  1, name = 'reverse-factory-1' },
}
if script.active_mods['early_construction'] then
    table.insert(Config.player_create.starting_items, { count =   1, name = 'early-construction-light-armor' })
    table.insert(Config.player_create.starting_items, { count =   1, name = 'early-construction-equipment' })
    table.insert(Config.player_create.starting_items, { count = 100, name = 'early-construction-robot' })
end

Config.dump_offline_inventories = {
    enabled = true,
    offline_timeout_mins = 30, -- time after which a player logs off that their inventory is provided to the team
    startup_gear_drop_hours = 24, -- time after which players will keep at least their armor when disconnecting
}
Config.paint.enabled = false
Config.permissions.presets.no_blueprints = true

Event.on_init(function()
    game.draw_resource_selection = false

    local p = game.forces.player
    p.technologies['mining-productivity-1'].enabled = false
    p.technologies['mining-productivity-2'].enabled = false
    p.technologies['mining-productivity-3'].enabled = false
    p.technologies['mining-productivity-4'].enabled = false

    game.forces.player.technologies['automation'].researched = true
    game.forces.player.technologies['reverse-factory-1'].researched = true

    p.manual_mining_speed_modifier = 1

    game.difficulty_settings.technology_price_multiplier = game.difficulty_settings.technology_price_multiplier * 5

    game.map_settings.enemy_evolution.time_factor = 0.000007 -- default 0.000004
    game.map_settings.enemy_evolution.destroy_factor = 0.000010 -- default 0.002
    game.map_settings.enemy_evolution.pollution_factor = 0.000000 -- Pollution has no affect on evolution default 0.0000009

    RS.get_surface().always_day = false
    RS.get_surface().peaceful_mode = true
end)

local terraforming = require 'map_gen.maps.danger_ores.modules.terraforming'
terraforming({start_size = 8 * 32, min_pollution = 400, max_pollution = 16000, pollution_increment = 4})

local rocket_launched = require 'map_gen.maps.danger_ores.modules.rocket_launched_simple'
rocket_launched({win_satellite_count = 500})

local restart_command = require 'map_gen.maps.danger_ores.modules.restart_command'
restart_command({scenario_name = 'danger-ore-scrap'})

local container_dump = require 'map_gen.maps.danger_ores.modules.container_dump'
container_dump({entity_name = 'scrap'})

local concrete_on_landfill = require 'map_gen.maps.danger_ores.modules.concrete_on_landfill'
concrete_on_landfill({tile = 'blue-refined-concrete'})

require 'map_gen.maps.danger_ores.modules.biter_drops'
require 'features.landfill_remover'
require 'map_gen.maps.danger_ores.modules.map_poll'

local config = {
    spawn_shape = b.square_diamond(36*2),
    start_ore_shape = b.square_diamond(44*2),
    no_resource_patch_shape = b.square_diamond(80*2),
    spawn_tile = 'landfill',
    main_ores = main_ores_config,
    main_ores_shuffle_order = true,
    main_ores_rotate = 0,
    water = water,
    water_scale = 1 / 96,
    water_threshold = 0.4,
    deepwater_threshold = 0.45,
    trees = trees,
    trees_scale = 1 / 64,
    trees_threshold = 0.4,
    trees_chance = 0.875,
    enemy = enemy,
    enemy_factor = 10 / (768 * 32),
    enemy_max_chance = 1 / 6,
    enemy_scale_factor = 32,
    fish_spawn_rate = 0.025,
}

return map(config)
