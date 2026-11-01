local Radial = require 'map_gen.maps.danger_ores.layouts.radial'

-- The sectors change size with distance. Far out, the copper and coal sectors' own iron (15% and
-- 18%) covers most of the iron.
return {
    name = 'Petals',
    settings = {
        main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_radial',
        main_ores_radial = {
            from = Radial.FROM,
            to = Radial.TO,
            inner = {['iron-ore'] = 51, ['copper-ore'] = 26, coal = 23},
            outer = {['iron-ore'] = 10, ['copper-ore'] = 55, coal = 35}
        },
        -- Three of each sector: as the sizes change, narrower sectors bend into curved spokes
        -- instead of an iron blob around spawn.
        main_ores_split_count = 3
    }
}
