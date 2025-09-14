
local H = require 'map_gen.maps.danger_ores.modules.helper'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Space Age')
ScenarioInfo.add_map_extra_info([[
	This map is covered in [item=coal] with mixed dense patches containing [item=iron-ore] [item=copper-ore] [item=stone] [item=calcite] [item=tungsten-ore] [item=holmium-ore].
	The patches alternate between [item=iron-ore] and [item=copper-ore] as the main resource.
]])

DOC.scenario_name = 'danger-ore-space-age'
DOC.map_config.main_ore_resource_patches_config = require 'map_gen.maps.danger_ores.compatibility.space-age.ores'
DOC.map_config.main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_patches'
DOC.map_config.main_ores = require 'map_gen.maps.danger_ores.compatibility.space-age.coal'
DOC.map_config.main_ores_rotate = nil
DOC.map_config.trees = require 'map_gen.maps.danger_ores.modules.trees'
DOC.map_config.tree_names = require 'map_gen.maps.danger_ores.compatibility.space-age.tree_names'
DOC.map_config.spawner_names = { 'biter-spawner', 'spitter-spawner', 'gleba-spawner-small', 'gleba-spawner' }
DOC.rocket_launched.enabled = false
DOC.technologies.unlocks['agriculture'] = { 'jellynut', 'yumako' }
DOC.technologies.unlocks['electromagnetic-science-pack'] = { 'lithium-processing' }
DOC.map_gen_settings.settings = H.empty_map_settings{
	'calcite',
	'coal',
	'copper-ore',
	'crude-oil',
	'fluorine_vent',
	'holmium-ore',
	'iron-ore',
	'lithium_brine',
	'scrap',
	'stone',
	'sulfuric_acid_geyser',
	'tungsten_ore',
	'uranium-ore',
}

require 'map_gen.maps.danger_ores.compatibility.space-age.victory'()

return Scenario.register(DOC)
