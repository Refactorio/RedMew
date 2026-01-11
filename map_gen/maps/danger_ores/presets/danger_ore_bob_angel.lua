local B = require 'map_gen.shared.builders'
local H = require 'map_gen.maps.danger_ores.modules.helper'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Bob & Angel\'s')
ScenarioInfo.add_map_extra_info([[
    This map is split in 7 sectors. Each sector has a main resource.
]])

DOC.scenario_name = 'danger-ore-bob-angel'
DOC.compatibility.redmew_data.remove_resource_patches = false
DOC.game.technology_price_multiplier = 5
DOC.map_config.main_ore_resource_patches_config = require 'map_gen.maps.danger_ores.compatibility.angel.resource_patches'
DOC.map_config.main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_patches'
DOC.map_config.main_ores = require 'map_gen.maps.danger_ores.compatibility.angel.ores'
DOC.map_config.resource_patches = nil
DOC.map_config.spawn_shape = B.circle(80)
DOC.map_config.start_ore_shape = B.circle(86)
DOC.map_config.fish_spawn_rate = 0.075
DOC.rocket_launched.enabled = false
DOC.map_gen_settings.settings = H.empty_map_settings {
    'angels-ore1', -- Saphirite
    'angels-ore2', -- Jivolite
    'angels-ore3', -- stiratite
    'angels-ore4', -- Crotinium
    'angels-ore5', -- rubyte
    'angels-ore6', -- bobmonium
    'angels-fissure',     -- fissure
    'angels-natural-gas', -- gas well
    'coal',
    'crude-oil',
}
DOC.terraforming.enabled = false

local rocket_launched = require 'map_gen.maps.danger_ores.modules.rocket_launched'
rocket_launched {
    recent_chunks_max = 10,
    ticks_between_waves = 60 * 30,
    enemy_factor = 5,
    max_enemies_per_wave_per_chunk = 60,
    extra_rockets = 100,
}

return Scenario.register(DOC)
