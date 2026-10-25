local DOC = require 'map_gen.maps.danger_ores.configuration'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'
local Factory = require 'map_gen.maps.danger_ores.config.main_ores_factory'
local RadialRichness = require 'map_gen.maps.danger_ores.modules.radial_richness'

ScenarioInfo.set_map_name('Danger Ores - Riches')
ScenarioInfo.add_map_extra_info([[
  This map is split in three sectors [item=iron-ore] [item=copper-ore] [item=coal].
  Each sector has a main resource and the other resources at a lower ratio.
  How rich each sector is changes with distance, to match what 1000 satellites on coal power use:
  iron is rich around spawn for research and building, copper and coal further out for rockets.
]])

DOC.scenario_name = 'danger-ore-riches'

-- Richness multipliers fitted to 1000 satellites with the canonical mixes and equal sectors:
-- research and building (about 11M ore) use mostly iron and come out of the ground within ~200
-- tiles of spawn; rockets on a half-moduled, coal-powered factory use mostly copper and coal,
-- out to ~410 tiles. The multipliers average 1 at every distance, so each ring holds as much
-- ore as on the standard map. The thin sectors are cheap ground to clear for building.
local function richness(inner, outer)
    return RadialRichness.curve {inner = inner, outer = outer, from = 200, to = 350}
end

DOC.map_config.main_ores = Factory.default()
    :richness(richness(1.53, 0.30), 'iron-ore')
    :richness(richness(0.78, 1.65), 'copper-ore')
    :richness(richness(0.69, 1.05), 'coal')

return Scenario.register(DOC)
