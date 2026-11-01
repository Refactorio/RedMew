local DOC = require 'map_gen.maps.danger_ores.configuration'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Randomizer')
ScenarioInfo.add_map_extra_info([[
  Every map is a new mix: one of the Danger Ores ore layouts [item=iron-ore] [item=copper-ore] [item=coal],
  with lakes, rivers or an archipelago, and maybe the walls of a citadel or fault lines on top.
]])

DOC.scenario_name = 'danger-ore-randomizer'
DOC.randomizer.enabled = true

return Scenario.register(DOC)
