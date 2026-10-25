local DOC = require 'map_gen.maps.danger_ores.configuration'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Petals')
ScenarioInfo.add_map_extra_info([[
  This map is split in three sectors [item=iron-ore] [item=copper-ore] [item=coal].
  Each sector has a main resource and the other resources at a lower ratio.
  The sectors change size with distance, to match what 1000 satellites on coal power use:
  iron-heavy around spawn for research and building, copper-heavy further out for rockets.
]])

DOC.scenario_name = 'danger-ore-petals'
DOC.map_config.main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_radial'
-- Weights fitted to 1000 satellites with the canonical mixes: research and building (about 11M
-- ore) use mostly iron and come out of the ground within ~200 tiles of spawn; rockets on a
-- half-moduled, coal-powered factory use mostly copper and coal, out to ~410 tiles. Far out, the
-- copper and coal sectors' own iron (15% and 18%) covers most of the iron.
DOC.map_config.main_ores_radial = {
    from = 200,
    to = 350,
    inner = {['iron-ore'] = 51, ['copper-ore'] = 26, coal = 23},
    outer = {['iron-ore'] = 10, ['copper-ore'] = 55, coal = 35}
}
-- Three of each sector: as the sizes change, narrower sectors bend into curved spokes instead
-- of an iron blob around spawn.
DOC.map_config.main_ores_split_count = 3

return Scenario.register(DOC)
