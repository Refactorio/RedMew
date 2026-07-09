-- The 4-ore X-Cross config: canonical mixes and curves. 3way_ores derives from this.
local b = require 'map_gen.shared.builders'
local Factory = require 'map_gen.maps.danger_ores.config.main_ores_factory'

return Factory.main_ores {
    ores = {'copper-ore', 'coal', 'iron-ore', 'stone'},
    start = b.euclidean_value(0, 0.35),
    value = b.exponential_value(0, 0.07, 1.45)
}
