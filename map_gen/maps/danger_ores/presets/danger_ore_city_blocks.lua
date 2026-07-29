local Config = require 'config'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local CityBlocks = require 'map_gen.maps.danger_ores.modules.city_blocks'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - City Blocks')
ScenarioInfo.add_map_extra_info([[
  A grid of isolated ore rooms, each dominated by a single resource
  [item=iron-ore] [item=copper-ore] [item=coal], with the others mixed
  in at a lower ratio. The spawn room splits them across its quadrants.
  Rooms are separated by paved rail corridors carrying a ready-made
  double-track network: continuous lines ring every room and meet at a
  signalled roundabout on every corner, and the rails are yours --
  extend them, reroute them, mine them. Rails, signals, train stops,
  power poles and trains are the only things buildable on the
  corridors, and belts cannot cross them: trains are your logistics.
]])

local starting_items = Config.player_create.starting_items
starting_items[#starting_items + 1] = { count = 100, name = 'rail' }
starting_items[#starting_items + 1] = { count = 2, name = 'train-stop' }
starting_items[#starting_items + 1] = { count = 10, name = 'rail-signal' }
starting_items[#starting_items + 1] = { count = 1, name = 'locomotive' }
starting_items[#starting_items + 1] = { count = 2, name = 'cargo-wagon' }
starting_items[#starting_items + 1] = { count = 50, name = 'coal' }

-- Half the canonical density: a room is 4x4 chunks of solid single-ore field, so at full
-- richness one room outlasts anything you can build in it and clearing ground stops mattering.
local main_ores = require('map_gen.maps.danger_ores.config.vanilla_ores'):scale_richness(0.5)

DOC.biter_drops.enabled = false
DOC.scenario_name = 'danger-ore-city-blocks'
DOC.terraforming.enabled = false
DOC.map_config.main_ores_builder = CityBlocks.main_ores_builder
DOC.map_config.main_ores = main_ores
DOC.map_config.main_ores_rotate = nil
DOC.map_config.main_ores_shuffle_order = false
DOC.game.on_init = function()
  local technologies = game.forces.player.technologies
  for _, tech in pairs({ 'railway', 'automated-rail-transportation' }) do
    if technologies[tech] then
      technologies[tech].researched = true
    end
  end
end

CityBlocks.register({ main_ores = main_ores })

return Scenario.register(DOC)
