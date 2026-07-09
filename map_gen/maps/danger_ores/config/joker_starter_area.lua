-- The Joker starter area: canonical sectors with time-budgeted richness -- each patch
-- holds roughly this many hours of a single electric mining drill's output. Coal sits
-- on the small budget so players can mine through it to expand the starter area more
-- easily. Plus a token super-rich uranium entry.
local b = require 'map_gen.shared.builders'
local Factory = require 'map_gen.maps.danger_ores.config.main_ores_factory'

local mine_speed = 0.5 / 10 -- 0.5 ore/s per electric mining drill
local low = 60 * 60 * 4 * mine_speed -- 4h
local medium = 60 * 60 * 24 * mine_speed -- 24h

return Factory.default()
    :add_ore('stone')
    :add_ore('uranium-ore', {tiles = false, value = function() return 1e6 end})
    :start_value(1)
    :richness(b.exponential_value(medium, 0.07, 1.45))
    :richness(b.exponential_value(low, 0.07, 1.45), 'coal')
