local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'
local Event = require 'utils.event'
local b = require 'map_gen.shared.builders'
local Config = require 'config'

local ScenarioInfo = require 'features.gui.info'
ScenarioInfo.set_map_name('Danger Ore Expanse')
ScenarioInfo.set_map_description([[
  DangerOres meets The Expanse!

  Clear the ore to expand the base,
  focus mining efforts on specific sectors to ensure
  proper material ratios, consume as much resources as possible!

                            -- AND --

  Feed the hungry blue chests with the materials they require.
  The Elder Tree and the Infinity Stone you find at spawn will
  provide you with all the wood and ores you ever desired.
]])
ScenarioInfo.add_map_extra_info([[
  This map is split in three sectors [item=iron-ore] [item=copper-ore] [item=coal].
  Each sector has a main resource and the other resources at a lower ratio.

  You may not build the factory on ore patches. Exceptions:
  [item=burner-mining-drill] [item=electric-mining-drill] [item=pumpjack] [item=small-electric-pole] [item=medium-electric-pole] [item=big-electric-pole] [item=substation] [item=car] [item=tank] [item=spidertron] [item=locomotive] [item=cargo-wagon] [item=fluid-wagon] [item=artillery-wagon]
  [item=transport-belt] [item=fast-transport-belt] [item=express-transport-belt]  [item=underground-belt] [item=fast-underground-belt] [item=express-underground-belt] [item=rail] [item=rail-signal] [item=rail-chain-signal] [item=train-stop]

  The map size is restricted by the Hungry Chests. Provide the requested materials to unlock new chunks.
  Use the Elder Tree [entity=tree-01], the Infinity Rock [entity=rock-huge], and the Precious Oil patch [entity=crude-oil] located at spawn [gps=0,0.redmew]
  to draw more resources when in need, but always favor Danger Ores first if you can.
  If you find yourself stuck with the requests, insert a Coin [item=coin] into the Hungry Chest [item=logistic-chest-requester] to reroll the request.
  You can fulfill part of the request & then reroll to change the remaining part (it will always reroll based on its remaining content to be fulfilled).
  Unlocking new land may or may not reward you with another Coin.
]])

ScenarioInfo.set_new_info([[
2024-08-01:
  - Fixed allowed entities list with Mk2-3 drills
  - Fixed typos in description
2024-04-08:
  - Forked from DO/terraforming
  - Added DO/expanse
  - Lowered tech multiplier 25 > 5
2024-04-17:
  - Fixed incorrect request computation
  - Fixed persistent chests on new chunk unlocks
  - Added chests for each new expansion border
  - Reduced pre_multiplier from 0.33 >s 0.20
]])

ScenarioInfo.add_extra_rule({'info.rules_text_danger_ore'})

local map = require 'map_gen.maps.danger_ores.modules.map'
local main_ores_config = require 'map_gen.maps.danger_ores.config.vanilla_ores'
local resource_patches = require 'map_gen.maps.danger_ores.modules.resource_patches'
local resource_patches_config = require 'map_gen.maps.danger_ores.config.vanilla_resource_patches'
local water = require 'map_gen.maps.danger_ores.modules.water'
local trees = require 'map_gen.maps.danger_ores.modules.trees'
local enemy = require 'map_gen.maps.danger_ores.modules.enemy'
--local dense_patches = require 'map_gen.maps.danger_ores.modules.dense_patches'

local banned_entities = require 'map_gen.maps.danger_ores.modules.banned_entities'
local allowed_entities = require 'map_gen.maps.danger_ores.config.deadlock_beltboxes_allowed_entities'
banned_entities(allowed_entities)

RS.set_map_gen_settings({
    MGSP.grass_only,
    MGSP.enable_water,
    {terrain_segmentation = 'normal', water = 'normal'},
    MGSP.starting_area_very_low,
    MGSP.ore_oil_none,
    MGSP.enemy_none,
    MGSP.cliff_none,
    MGSP.tree_none
})

Config.market.enabled = false
Config.player_rewards.enabled = true
Config.player_create.starting_items = {
  {amount =  1, name = 'burner-mining-drill'},
  {amount =  1, name = 'stone-furnace'},
  {amount =  1, name = 'wood'},
  {amount =  1, name = 'pistol'},
  {amount = 20, name = 'firearm-magazine'},
  {amount =  5, name = 'coin'},
}
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

    game.difficulty_settings.technology_price_multiplier = 5
    game.forces.player.technologies.logistics.researched = true
    game.forces.player.technologies.automation.researched = true

    game.map_settings.enemy_evolution.time_factor = 0.000007 -- default 0.000004
    game.map_settings.enemy_evolution.destroy_factor = 0.000010 -- default 0.002
    game.map_settings.enemy_evolution.pollution_factor = 0.000000 -- Pollution has no affect on evolution default 0.0000009

    game.forces.player.manual_mining_speed_modifier = 1

    RS.get_surface().always_day = true
    RS.get_surface().peaceful_mode = true
end)

local expanse = require 'map_gen.maps.danger_ores.modules.expanse'
expanse({start_size = 8*32}) -- 8x32

local rocket_launched = require 'map_gen.maps.danger_ores.modules.rocket_launched_simple'
rocket_launched({win_satellite_count = 100})

local restart_command = require 'map_gen.maps.danger_ores.modules.restart_command'
restart_command({scenario_name = 'danger-ore-expanse'})

local container_dump = require 'map_gen.maps.danger_ores.modules.container_dump'
container_dump({entity_name = 'coal'})

local concrete_on_landfill = require 'map_gen.maps.danger_ores.modules.concrete_on_landfill'
concrete_on_landfill({tile = 'blue-refined-concrete'})

local config = {
    spawn_shape = b.circle(36),
    start_ore_shape = b.circle(44),
    no_resource_patch_shape = b.circle(80),
    main_ores = main_ores_config,
    main_ores_shuffle_order = true,
    main_ores_rotate = 30,
    resource_patches = resource_patches,
    resource_patches_config = resource_patches_config,
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
    --dense_patches = dense_patches,
    dense_patches_scale = 1 / 48,
    dense_patches_threshold = 0.55,
    dense_patches_multiplier = 25
}

return map(config)
