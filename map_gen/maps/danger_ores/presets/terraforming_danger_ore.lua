local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'
local Event = require 'utils.event'
local b = require 'map_gen.shared.builders'

local ScenarioInfo = require 'features.gui.info'
ScenarioInfo.set_map_name('Terraforming Danger Ore')
ScenarioInfo.set_map_description(
    [[
Clear the ore to expand the base,
focus mining efforts on specific quadrants to ensure
proper material ratios, expand the map with pollution!
]]
)
ScenarioInfo.add_map_extra_info(
    [[
This map is split in four quadrants. Each quadrant has a main resource.
 [item=iron-ore] north, [item=copper-ore] south, [item=coal] east, [item=stone] west

You may not build the factory on ore patches. Exceptions:
 [item=burner-mining-drill] [item=electric-mining-drill] [item=pumpjack] [item=small-electric-pole] [item=medium-electric-pole] [item=big-electric-pole] [item=substation] [item=car] [item=tank] [item=spidertron]
 [item=transport-belt] [item=fast-transport-belt] [item=express-transport-belt]  [item=underground-belt] [item=fast-underground-belt] [item=express-underground-belt] [item=rail]

The map size is restricted to the pollution generated. A significant amount of
pollution must affect a section of the map before it is revealed. Pollution
does not affect biter evolution.]]
)

ScenarioInfo.set_map_description(
    [[
Clear the ore to expand the base,
focus mining efforts on specific quadrants to ensure
proper material ratios, expand the map with pollution!
]]
)
ScenarioInfo.set_new_info(
    [[
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

2020-09-02
 - Destroyed chests dump their content as coal ore.
]]
)

local map = require 'map_gen.maps.danger_ores.modules.map'
local main_ores_config = require 'map_gen.maps.danger_ores.config.vanilla_ores'
local resource_patches = require 'map_gen.maps.danger_ores.modules.resource_patches'
local resource_patches_config = require 'map_gen.maps.danger_ores.config.vanilla_resource_patches'
local water = require 'map_gen.maps.danger_ores.modules.water'
local trees = require 'map_gen.maps.danger_ores.modules.trees'
local enemy = require 'map_gen.maps.danger_ores.modules.enemy'
local dense_patches = require 'map_gen.maps.danger_ores.modules.dense_patches'

local banned_entities = require 'map_gen.maps.danger_ores.modules.banned_entities'
local allowed_entities = require 'map_gen.maps.danger_ores.config.vanilla_allowed_entities'
banned_entities(allowed_entities)

RS.set_map_gen_settings(
    {
        MGSP.grass_only,
        MGSP.enable_water,
        {
            terrain_segmentation = 'normal',
            water = 'normal'
        },
        MGSP.starting_area_very_low,
        MGSP.ore_oil_none,
        MGSP.enemy_none,
        MGSP.cliff_none,
        MGSP.tree_none
    }
)

Event.on_init(
    function()
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

        RS.get_surface().always_day = true
    end
)

local terraforming = require 'map_gen.maps.danger_ores.modules.terraforming'
terraforming(
    {
        start_size = 8 * 32,
        min_pollution = 300,
        max_pollution = 5000,
        pollution_increment = 2.5
    }
)

local rocket_launched = require 'map_gen.maps.danger_ores.modules.rocket_launched'
rocket_launched(
    {
        recent_chunks_max = 10,
        ticks_between_waves = 60 * 30,
        enemy_factor = 3,
        max_enemies_per_wave_per_chunk = 60,
        extra_rockets = 100
    }
)

local container_dump = require 'map_gen.maps.danger_ores.modules.container_dump'
container_dump({entity_name = 'coal'})

local config = {
    spawn_shape = b.circle(64),
    start_ore_shape = b.circle(68),
    main_ores = main_ores_config,
    --main_ores_shuffle_order = true,
    main_ores_rotate = 45,
    resource_patches = resource_patches,
    resource_patches_config = resource_patches_config,
    water = water,
    water_scale = 1 / 96,
    water_threshold = 0.5,
    deepwater_threshold = 0.55,
    trees = trees,
    trees_scale = 1 / 64,
    trees_threshold = 0.4,
    trees_chance = 0.875,
    enemy = enemy,
    enemy_factor = 10 / (768 * 32),
    enemy_max_chance = 1 / 6,
    enemy_scale_factor = 32,
    fish_spawn_rate = 0.025,
    dense_patches = dense_patches,
    dense_patches_scale = 1 / 48,
    dense_patches_threshold = 0.55,
    dense_patches_multiplier = 50
}

return map(config)
