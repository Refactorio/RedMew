-- The 4-ore X-Cross config: canonical mixes except for a coal-heavier coal sector,
-- with an exponential start (no guaranteed-rich spawn). 3way_ores derives from this.
local b = require 'map_gen.shared.builders'
local Factory = require 'map_gen.maps.danger_ores.config.main_ores_factory'

local value = b.exponential_value(0, 0.15, 1.3)

return Factory.main_ores {
    ores = {
        'copper-ore',
        {name = 'coal', mix = 'coal-rich'},
        'iron-ore',
        'stone'
    },
    start = value,
    value = value
}
