local DOC = require 'map_gen.maps.danger_ores.configuration'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'
local Factory = require 'map_gen.maps.danger_ores.config.main_ores_factory'
local RadialRichness = require 'map_gen.maps.danger_ores.modules.radial_richness'

ScenarioInfo.set_map_name('Danger Ores - Bloom')
ScenarioInfo.add_map_extra_info([[
  This map is split in sectors [item=iron-ore] [item=copper-ore] [item=coal].
  Each sector has a main resource and the other resources at a lower ratio.
  Both the size and the richness of each sector change with distance, to match what 1000
  satellites on coal power use: iron around spawn for research and building, copper and coal
  further out for rockets.
]])

DOC.scenario_name = 'danger-ore-bloom'

-- Petals (sector sizes) and Riches (richness) each make the whole change from the iron-heavy
-- early game (within ~200 tiles) to the copper- and coal-heavy rockets (out to ~410 tiles).
-- Bloom goes halfway on each: size times richness gives the same ore at every distance as
-- either, so sectors bend half as much as on Petals and are half as lean or rich as on Riches.
local FROM, TO = 200, 350

DOC.map_config.main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_radial'
DOC.map_config.main_ores_radial = {
    from = FROM,
    to = TO,
    inner = {['iron-ore'] = 42, ['copper-ore'] = 30, coal = 28},
    outer = {['iron-ore'] = 19, ['copper-ore'] = 45, coal = 36}
}
-- Two of each sector: the sizes change half as much as on Petals, so wider sectors stay spokes.
DOC.map_config.main_ores_split_count = 2

local function richness(inner, outer)
    return RadialRichness.curve {inner = inner, outer = outer, from = FROM, to = TO}
end

DOC.map_config.main_ores = Factory.default()
    :richness(richness(1.21, 0.53), 'iron-ore')
    :richness(richness(0.87, 1.22), 'copper-ore')
    :richness(richness(0.82, 0.97), 'coal')

return Scenario.register(DOC)
