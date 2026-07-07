local B = require 'map_gen.shared.builders'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local ModCompatibility = require 'utils.mod_compatibility'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ModCompatibility.check {
    dependencies = {{ name = 'gridlocked' }}
}

ScenarioInfo.set_map_name('Danger Ores - Gridlocked')
ScenarioInfo.add_map_extra_info([[
    This map is divided in quadrants of [item=iron-ore] [item=copper-ore] [item=coal] [item=stone].
    Each sector has a main resource and the other resources at a lower ratio.

    Unlock new chunks via [font=default-bold]Chunk claim tool (Alt + K)[/font].
    Chunk purchases can be reverted within 30s from purchase.
    Chunk points are awarded by completing [technology=gl-additional-chunk-space-science-pack] Technology: Additional chunks.
    Chunk cost is computed based on adjacient chunks.
]])

DOC.scenario_name = 'danger-ore-gridlocked'
DOC.map_config.main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_grid_factory'
DOC.map_config.main_ores = require 'map_gen.maps.danger_ores.config.vanilla_ores_gridlocked'
DOC.map_config.spawn_tile = 'orange-refined-concrete'
DOC.map_config.spawn_shape = B.circle(20)
DOC.map_config.start_ore_shape = B.circle(40)
DOC.map_config.no_resource_patch_shape = B.circle(80)
DOC.terraforming.enabled = false
DOC.game.technology_price_multiplier = 10

return Scenario.register(DOC)
