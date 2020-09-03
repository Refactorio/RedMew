local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'
local Event = require 'utils.event'
local b = require 'map_gen.shared.builders'
local Token = require 'utils.token'

local ScenarioInfo = require 'features.gui.info'
ScenarioInfo.set_map_name('Danger Ores')
ScenarioInfo.set_map_description(
    [[
Clear the ore to expand the base:
build extensive mining efforts, create large smelting arrays,
use proper material ratios, and defend from enemies!
]]
)
ScenarioInfo.add_map_extra_info(
    [[You may not build the factory on ore patches. Exceptions:
 [item=burner-mining-drill] [item=electric-mining-drill] [item=pumpjack] [item=small-electric-pole] [item=medium-electric-pole] [item=big-electric-pole] [item=substation] [item=car] [item=tank]
 [item=transport-belt] [item=fast-transport-belt] [item=express-transport-belt]  [item=underground-belt] [item=fast-underground-belt] [item=express-underground-belt] ]]
)

local shared_globals = {}
Token.register_global(shared_globals)
_G.danger_ore_shared_globals = shared_globals

local map = require 'map_gen.maps.danger_ores.modules.map'
local main_ores_config = require 'map_gen.maps.danger_ores.config.vanilla_ores'
local resource_patches = require 'map_gen.maps.danger_ores.modules.resource_patches'
local resource_patches_config = require 'map_gen.maps.danger_ores.config.vanilla_resource_patches'
local dense_patches = require 'map_gen.maps.danger_ores.modules.dense_patches'

local banned_entities = require 'map_gen.maps.danger_ores.modules.banned_entities'
local allowed_entities = require 'map_gen.maps.danger_ores.config.vanilla_allowed_entities'
banned_entities(allowed_entities)

RS.set_map_gen_settings(
    {
        MGSP.ore_oil_none,
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

        game.difficulty_settings.technology_price_multiplier = 20
        game.forces.player.technologies.logistics.researched = true
        game.forces.player.technologies.automation.researched = true

        game.map_settings.enemy_evolution.time_factor = 0.000002 -- default 0.000004
        game.map_settings.enemy_evolution.destroy_factor = 0.0009 -- default 0.002
        game.map_settings.enemy_evolution.pollution_factor = 0.0000015 -- default 0.0000009
    end
)

local container_dump = require 'map_gen.maps.danger_ores.modules.container_dump'
container_dump({entity_name = 'coal'})

local config = {
    spawn_shape = b.circle(64),
    start_ore_shape = b.circle(68),
    main_ores = main_ores_config,
    --main_ores_shuffle_order = true,
    resource_patches = resource_patches,
    resource_patches_config = resource_patches_config,
    dense_patches = dense_patches,
    dense_patches_scale = 1 / 48,
    dense_patches_threshold = 0.5,
    dense_patches_multiplier = 50
}

return map(config, shared_globals)
