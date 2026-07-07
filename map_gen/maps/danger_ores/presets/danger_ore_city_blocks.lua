local Config = require 'config'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local CityBlocks = require 'map_gen.maps.danger_ores.modules.city_blocks'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - City Blocks')
ScenarioInfo.add_map_extra_info([[
  A maze of isolated ore rooms, each dominated by a single resource
  [item=iron-ore] [item=copper-ore] [item=coal] [item=stone].
  The spawn room carries all four ores, one per quadrant. Rooms are
  separated by paved rail corridors carrying a ready-made double-track
  network: continuous lines ring every room and meet at a signalled
  roundabout on every corner, and the rails are yours -- extend them, reroute them, mine them.
  Rails, signals, train stops, power poles and trains are the only
  things buildable on the corridors, and belts cannot cross them:
  trains are your logistics.
]])

local starting_items = Config.player_create.starting_items
starting_items[#starting_items + 1] = { count = 100, name = 'rail' }
starting_items[#starting_items + 1] = { count = 2, name = 'train-stop' }
starting_items[#starting_items + 1] = { count = 10, name = 'rail-signal' }
starting_items[#starting_items + 1] = { count = 1, name = 'locomotive' }
starting_items[#starting_items + 1] = { count = 2, name = 'cargo-wagon' }
starting_items[#starting_items + 1] = { count = 50, name = 'coal' }

DOC.biter_drops.enabled = false
DOC.scenario_name = 'danger-ore-city-blocks'
DOC.terraforming.enabled = false
DOC.map_config.main_ores_builder = CityBlocks.main_ores_builder
DOC.map_config.main_ores = require 'map_gen.maps.danger_ores.config.city_blocks_ores'
DOC.map_config.main_ores_rotate = nil
DOC.game.on_init = function()
  local technologies = game.forces.player.technologies
  for _, tech in pairs({ 'railway', 'automated-rail-transportation' }) do
    if technologies[tech] then
      technologies[tech].researched = true
    end
  end
end

CityBlocks.register()

return Scenario.register(DOC)
