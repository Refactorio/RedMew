
local DOC = require 'map_gen.maps.danger_ores.configuration'
local Layouts = require 'map_gen.maps.danger_ores.modules.layouts'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Patches')
ScenarioInfo.add_map_extra_info([[
	This map is covered in [item=coal] with mixed dense patches containing [item=iron-ore] [item=copper-ore] [item=stone].
	The patches alternate between [item=iron-ore] and [item=copper-ore] as the main resource.
]])

DOC.scenario_name = 'danger-ore-patches'
Layouts.apply(DOC.map_config, require 'map_gen.maps.danger_ores.layouts.patches')

return Scenario.register(DOC)
