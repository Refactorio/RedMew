local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'
local Event = require 'utils.event'
local b = require 'map_gen.shared.builders'
local Token = require 'utils.token'

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
 [item=iron-ore] north east, [item=copper-ore] south west, [item=coal] north west, [item=stone] south east

You may not build the factory on ore patches. Exceptions:
 [item=burner-mining-drill] [item=electric-mining-drill] [item=pumpjack] [item=small-electric-pole] [item=medium-electric-pole] [item=big-electric-pole] [item=substation] [item=car] [item=tank]
 [item=transport-belt] [item=fast-transport-belt] [item=express-transport-belt]  [item=underground-belt] [item=fast-underground-belt] [item=express-underground-belt]

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

local shared_globals = {}
Token.register_global(shared_globals)
_G.danger_ore_shared_globals = shared_globals

local map = require 'map_gen.maps.danger_ores.modules.map'
local main_ores_config = require 'map_gen.maps.danger_ores.config.bob_ores'
local resource_patches = require 'map_gen.maps.danger_ores.modules.resource_patches'
local resource_patches_config = require 'map_gen.maps.danger_ores.config.bob_resource_patches'
local water = require 'map_gen.maps.danger_ores.modules.water'
local trees = require 'map_gen.maps.danger_ores.modules.trees'
local enemy = require 'map_gen.maps.danger_ores.modules.enemy'
local dense_patches = require 'map_gen.maps.danger_ores.modules.dense_patches'

local banned_entities = require 'map_gen.maps.danger_ores.modules.banned_entities'
local allowed_entities = require 'map_gen.maps.danger_ores.config.bob_allowed_entities'
banned_entities(allowed_entities)

local ores_names = {
    'coal',
    'copper-ore',
    'crude-oil',
    'iron-ore',
    'stone',
    'uranium-ore',
    'bauxite-ore',
    'cobalt-ore',
    'gem-ore',
    'gold-ore',
    'lead-ore',
    'nickel-ore',
    'quartz',
    'rutile-ore',
    'silver-ore',
    'sulfur',
    'tin-ore',
    'tungsten-ore',
    'zinc-ore',
    'thorium-ore'
}
local ore_oil_none = {}
for _, v in pairs(ores_names) do
    ore_oil_none[v] = {
        frequency = 1,
        richness = 1,
        size = 0
    }
end
ore_oil_none = {autoplace_controls = ore_oil_none}

RS.set_map_gen_settings(
    {
        MGSP.grass_only,
        MGSP.enable_water,
        {
            terrain_segmentation = 'normal',
            water = 'normal'
        },
        MGSP.starting_area_very_low,
        ore_oil_none,
        MGSP.enemy_none,
        MGSP.cliff_none
    }
)

Event.on_init(
    function()
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
    end
)

local terraforming = require 'map_gen.maps.danger_ores.modules.terraforming'
terraforming(
    {
        start_size = 8 * 32,
        min_pollution = 400,
        max_pollution = 20000,
        pollution_increment = 4
    }
)

local rocket_launched = require 'map_gen.maps.danger_ores.modules.rocket_launched'
rocket_launched(
    {
        recent_chunks_max = 10,
        ticks_between_waves = 60 * 30,
        enemy_factor = 5,
        max_enemies_per_wave_per_chunk = 60,
        extra_rockets = 100
    },
    shared_globals
)

local container_dump = require 'map_gen.maps.danger_ores.modules.container_dump'
container_dump({entity_name = 'coal'})

local config = {
    spawn_shape = b.circle(80),
    start_ore_shape = b.circle(86),
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
    trees_threshold = -0.25,
    trees_chance = 0.125,
    enemy = enemy,
    enemy_factor = 10 / (768 * 32),
    enemy_max_chance = 1 / 6,
    enemy_scale_factor = 32,
    fish_spawn_rate = 0.025,
    dense_patches = dense_patches,
    dense_patches_scale = 1 / 48,
    dense_patches_threshold = 0.5,
    dense_patches_multiplier = 50
}

return map(config, shared_globals)
