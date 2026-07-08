-- vanilla_ores with a steeper early richness curve, tuned for the One Direction map.
local b = require 'map_gen.shared.builders'
local Factory = require 'map_gen.maps.danger_ores.config.main_ores_factory'

return Factory.main_ores {
    ores = {'copper-ore', 'coal', 'iron-ore'},
    start = b.euclidean_value(0, 0.35),
    value = b.exponential_value(0, 0.15, 1.2)
}
