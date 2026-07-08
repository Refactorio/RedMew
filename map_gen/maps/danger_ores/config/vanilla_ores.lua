-- The standard 3-ore main-ores config: canonical tiles and mixes from the factory,
-- with the classic richness curves. Order is significant: it maps to ore indices.
local b = require 'map_gen.shared.builders'
local Factory = require 'map_gen.maps.danger_ores.config.main_ores_factory'

return Factory.main_ores {
    ores = {'copper-ore', 'coal', 'iron-ore'},
    start = b.euclidean_value(0, 0.35),
    value = b.exponential_value(0, 0.07, 1.45)
}
