-- The Gridlocked config: canonical mixes on landfill tiles, with a rich guaranteed
-- floor (both curves offset by 50) and weighted ore order (iron-heavy, stone-light).
local b = require 'map_gen.shared.builders'
local Factory = require 'map_gen.maps.danger_ores.config.main_ores_factory'

return Factory.main_ores {
    ores = {
        {name = 'iron-ore', weight = 10},
        {name = 'coal', weight = 8},
        {name = 'copper-ore', weight = 7},
        {name = 'stone', weight = 2}
    },
    start = b.euclidean_value(50, 0.75),
    value = b.exponential_value(50, 0.003, 2.25),
    tiles = {'landfill'}
}
