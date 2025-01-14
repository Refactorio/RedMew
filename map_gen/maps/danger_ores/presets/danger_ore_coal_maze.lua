local B = require 'map_gen.shared.builders'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Coal Maze')
ScenarioInfo.add_map_extra_info([[
	This maze is covered in [item=coal] with mixed dense patches containing [item=iron-ore] [item=copper-ore] [item=stone].
	The patches alternate between [item=iron-ore] and [item=copper-ore] as the main resource.
]])

DOC.scenario_name = 'danger-ore-coal-maze'
DOC.map_config.spawn_shape = B.translate(B.rectangle(64), 2, 2)
DOC.map_config.start_ore_shape = B.translate(B.rectangle(68), 2, 2)
DOC.map_config.no_resource_patch_shape = B.translate(B.rectangle(80), 2, 2)
DOC.map_config.main_ore_resource_patches_config = require 'map_gen.maps.danger_ores.config.main_ore_resource_patches'
DOC.map_config.main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_patches'
DOC.map_config.main_ores = require 'map_gen.maps.danger_ores.config.coal'
DOC.map_config.main_ores_rotate = nil
DOC.maze.enabled = true
DOC.terraforming.enabled = false

return Scenario.register(DOC)
