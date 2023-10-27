local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'
local Event = require 'utils.event'
local Token = require 'utils.token'
local Task = require 'utils.task'
local b = require 'map_gen.shared.builders'
local Config = require 'config'

local ScenarioInfo = require 'features.gui.info'
ScenarioInfo.set_map_name('Danger Ore x Krastorio2')
ScenarioInfo.set_map_description([[
Clear the ore to expand the base,
focus mining efforts on specific sectors to ensure
proper material ratios, expand the map with pollution!
]])
ScenarioInfo.add_map_extra_info([[
This map is split in four sectors [item=iron-ore] [item=copper-ore] [item=coal] [item=stone].
Each sector has a main resource and the other resources at a lower ratio.

You may not build the factory on ore patches. Exceptions:
 [item=burner-mining-drill] [item=electric-mining-drill] [item=kr-electric-mining-drill-mk2] [item=kr-electric-mining-drill-mk3] [item=pumpjack] [item=kr-mineral-water-pumpjack] [item=kr-quarry-drill]
 [item=small-electric-pole] [item=medium-electric-pole] [item=big-electric-pole] [item=substation] [item=kr-substation-mk2]
 [item=car] [item=tank] [item=kr-advanced-tank] [item=spidertron]
 [item=locomotive] [item=kr-nuclear-locomotive] [item=cargo-wagon] [item=fluid-wagon] [item=artillery-wagon]
 [item=transport-belt] [item=fast-transport-belt] [item=express-transport-belt] [item=kr-advanced-transport-belt] [item=kr-superior-transport-belt]
 [item=underground-belt] [item=fast-underground-belt] [item=express-underground-belt] [item=kr-advanced-underground-belt] [item=kr-superior-underground-belt]
 [item=rail] [item=rail-signal] [item=rail-chain-signal] [item=train-stop]

The map size is restricted to the pollution generated. A significant amount of
pollution must affect a section of the map before it is revealed. Pollution
does not affect biter evolution.
]])

ScenarioInfo.set_new_info([[
2023-10-26:
 - Reduced tech multiplier (10 -> 5)
 - Increased Uranium ore & Compact raw rare metals spawn radius (128 -> 192 tiles)
 - Eased terraforming requirements (8 -> 10 chunks, 9 -> 8 pollution increase, 24k -> 16k max pollution, 600 -> 400 min pollution)
 - Reduced rocket required to win (500 -> 100)
 - Removed Expensive Warehousing from required mods

2023-10-11:
 - Increased Uranium ore & Compact raw rare metals spawn radius to 128 tiles
 - Reduced Compact raw rare metals yield weight (8 -> 4)

2023-10-01:
 - Added K2 preset
]])

ScenarioInfo.add_extra_rule({'info.rules_text_danger_ore'})

global.config.redmew_qol.loaders = false

local map = require 'map_gen.maps.danger_ores.modules.map'
local main_ores_config = require 'map_gen.maps.danger_ores.config.krastorio2_ores'
local trees = require 'map_gen.maps.danger_ores.modules.trees'
local enemy = require 'map_gen.maps.danger_ores.modules.enemy'

local banned_entities = require 'map_gen.maps.danger_ores.modules.banned_entities'
local allowed_entities = require 'map_gen.maps.danger_ores.config.krastorio2_allowed_entities'
banned_entities(allowed_entities)

local ore_oil_none = { autoplace_controls = {} }
for _, v in pairs({
    'coal',
    'crude-oil',
    'iron-ore',
    'copper-ore',
    'uranium-ore',
    'stone',
    'rare-metals',
    'mineral-water',
    'imersite',
}) do
    ore_oil_none.autoplace_controls[v] = { frequency = 1, richness = 1, size = 0 }
end

RS.set_map_gen_settings({
    MGSP.grass_only,
    MGSP.enable_water,
    {terrain_segmentation = 'normal', water = 'normal'},
    MGSP.starting_area_very_low,
    ore_oil_none,
    MGSP.enemy_none,
    MGSP.cliff_none,
    {autoplace_controls = {trees = {frequency = 1, richness = 1, size = 1}}}
})
-- Config.lazy_bastard.enabled = true
Config.market.enabled = false
Config.player_rewards.enabled = false
Config.player_create.starting_items = {
    {name = 'assembling-machine-1', count = 1},
    {name = 'burner-mining-drill', count = 1},
    {name = 'copper-cable', count = 200},
    {name = 'electronic-circuit', count = 25},
    {name = 'iron-gear-wheel', count = 35},
    {name = 'iron-plate', count = 400},
    {name = 'kr-medium-container', count = 1},
    {name = 'kr-sentinel', count = 5},
    {name = 'kr-wind-turbine', count = 5},
    {name = 'lab', count = 1},
    {name = 'medium-electric-pole', count = 5},
    {name = 'steel-chest', count = 1},
    {name = 'stone-furnace', count = 1},
    {name = 'wood', count = 50},
}
if script.active_mods["early_construction"] then
    table.insert(Config.player_create.starting_items, {name = 'early-construction-light-armor', count = 1})
    table.insert(Config.player_create.starting_items, {name = 'early-construction-equipment', count = 1})
    table.insert(Config.player_create.starting_items, {name = 'early-construction-robot', count = 100})
end

Config.dump_offline_inventories = {
    enabled = true,
    offline_timout_mins = 30 -- time after which a player logs off that their inventory is provided to the team
}
Config.paint.enabled = false

local kr_remote = Token.register(function()
    -- enable creep on Redmew surface
    if remote.interfaces["kr-creep"] and remote.interfaces["kr-creep"]["set_creep_on_surface"] then
        remote.call( "kr-creep", "set_creep_on_surface", game.surfaces.redmew.index, true )
    end
    -- disable K2 radioactivity (if uranium is mixed with all the ores)
    if remote.interfaces["kr-radioactivity"] and remote.interfaces["kr-radioactivity"]["set_enabled"] then
        remote.call( "kr-radioactivity", "set_enabled", false )
    end
end)

Event.on_init(function()
    game.draw_resource_selection = false

    local p = game.forces.player
    p.technologies['mining-productivity-1'].enabled = false
    p.technologies['mining-productivity-2'].enabled = false
    p.technologies['mining-productivity-3'].enabled = false
    p.technologies['mining-productivity-4'].enabled = false
    p.technologies['mining-productivity-11'].enabled = false
    p.technologies['mining-productivity-16'].enabled = false
    p.technologies['kr-decorations'].enabled = false

    p.manual_mining_speed_modifier = 1

    game.difficulty_settings.technology_price_multiplier = game.difficulty_settings.technology_price_multiplier * 5

    game.map_settings.enemy_evolution.time_factor = 0.000007 -- default 0.000004
    game.map_settings.enemy_evolution.destroy_factor = 0.000010 -- default 0.002
    game.map_settings.enemy_evolution.pollution_factor = 0.000000 -- Pollution has no affect on evolution default 0.0000009

    RS.get_surface().always_day = true
    RS.get_surface().peaceful_mode = true

    Task.set_timeout_in_ticks(60, kr_remote)
end)

local terraforming = require 'map_gen.maps.danger_ores.modules.terraforming'
terraforming({start_size = 10 * 32, min_pollution = 400, max_pollution = 16000, pollution_increment = 8})

--[[ Win condition in K2: build intergalactic transceiver ]]
local rocket_launched = require 'map_gen.maps.danger_ores.modules.rocket_launched_krastorio2'
rocket_launched()

local restart_command = require 'map_gen.maps.danger_ores.modules.restart_command'
restart_command({scenario_name = 'danger-ore-krastorio2'})

local container_dump = require 'map_gen.maps.danger_ores.modules.container_dump'
container_dump({entity_name = 'coal'})

-- local concrete_on_landfill = require 'map_gen.maps.danger_ores.modules.concrete_on_landfill'
-- concrete_on_landfill({tile = 'blue-refined-concrete'})

local whitelist_stacked_recipes = require 'map_gen.maps.danger_ores.modules.remove_non_ore_stacked_recipes'
local allowed_recipes = require 'map_gen.maps.danger_ores.config.krastorio2_allowed_recipes'
whitelist_stacked_recipes(allowed_recipes)

require 'map_gen.maps.danger_ores.modules.biter_drops'

require 'map_gen.maps.danger_ores.modules.map_poll'

local config = {
    spawn_shape = b.circle(36),
    start_ore_shape = b.circle(44),
    no_resource_patch_shape = b.circle(80),
    spawn_tile = 'landfill',
    main_ores = main_ores_config,
    main_ores_shuffle_order = true,
    main_ores_rotate = 45,
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
    dense_patches_scale = 1 / 48,
    dense_patches_threshold = 0.55,
    dense_patches_multiplier = 25
}

return map(config)
