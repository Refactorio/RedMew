
local DOC = require 'map_gen.maps.danger_ores.configuration'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Patches')
ScenarioInfo.add_map_extra_info([[
	This map is covered in [item=coal] with mixed dense patches containing [item=iron-ore] [item=copper-ore] [item=stone].
	The patches alternate between [item=iron-ore] and [item=copper-ore] as the main resource.
]])

DOC.scenario_name = 'danger-ore-patches'
DOC.map_config.main_ore_resource_patches_config = require 'map_gen.maps.danger_ores.config.main_ore_resource_patches'
DOC.map_config.main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_patches'
DOC.map_config.main_ores = require 'map_gen.maps.danger_ores.config.coal'
DOC.map_config.main_ores_rotate = nil

return Scenario.register(DOC)
