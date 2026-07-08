-- vanilla_ores skinned entirely in landfill tiles, with a slightly flatter richness
-- curve. Used by maps where the whole ore field doubles as buildable ground.
local b = require 'map_gen.shared.builders'
local Factory = require 'map_gen.maps.danger_ores.config.main_ores_factory'

return Factory.main_ores {
    ores = {'copper-ore', 'coal', 'iron-ore'},
    start = b.euclidean_value(0, 0.35),
    value = b.exponential_value(0, 0.06, 1.55),
    tiles = {'landfill'}
}
