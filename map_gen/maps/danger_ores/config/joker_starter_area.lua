-- The Joker starter area: canonical mixes with time-budgeted richness -- each patch
-- holds roughly a day of a single electric mining drill's output. Plus a token
-- super-rich uranium entry.
local b = require 'map_gen.shared.builders'
local Factory = require 'map_gen.maps.danger_ores.config.main_ores_factory'

local mine_speed = 0.5 / 10 -- 0.5 ore/s per electric mining drill
local medium = 60 * 60 * 24 * mine_speed -- 24h

local medium_value = b.exponential_value(medium, 0.07, 1.45)

local config = Factory.main_ores {
    ores = {'copper-ore', 'coal', 'iron-ore', 'stone'},
    start = 1,
    value = medium_value
}

config[#config + 1] = {
    name = 'uranium-ore',
    start = 1,
    weight = 1,
    ratios = {
        {
            resource = b.resource(b.full_shape, 'uranium-ore', function() return 1e6 end),
            weight = 1
        }
    }
}

return config
