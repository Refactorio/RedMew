local DOC = require 'map_gen.maps.danger_ores.configuration'
local Config = require 'config'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Lazy One')
ScenarioInfo.add_map_extra_info([[
  This map is split in three sectors [item=iron-ore] [item=copper-ore] [item=coal].
  Each sector has a main resource and the other resources at a lower ratio.
]])

Config.permissions.presets.no_handcraft = true
Config.player_create.starting_items = {
  { count = 1,  name = 'steel-furnace' },
  { count = 1,  name = 'electric-mining-drill-2' },
  { count = 1,  name = 'medium-electric-pole' },
  { count = 1,  name = 'offshore-pump' },
  { count = 1,  name = 'boiler-2' },
  { count = 1,  name = 'steam-turbine' },
  { count = 1,  name = 'assembling-machine-2' },
  { count = 1,  name = 'fast-inserter' },
  { count = 1,  name = 'long-handed-inserter' },
  { count = 1,  name = 'steel-chest' },
  { count = 1,  name = 'storehouse-basic' },
  { count = 1,  name = 'lab' },
  { count = 1,  name = 'radar' },
  { count = 1,  name = 'rocket-fuel' },
}

DOC.scenario_name = 'danger-ore-lazy-one'
DOC.map_config.main_ores = require 'map_gen.maps.danger_ores.config.vanilla_ores_landfill'
DOC.map_config.spawn_tile = 'landfill'
DOC.map_config.water = nil

return Scenario.register(DOC)
