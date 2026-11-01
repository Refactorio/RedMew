local Factory = require 'map_gen.maps.danger_ores.config.main_ores_factory'
local Radial = require 'map_gen.maps.danger_ores.layouts.radial'

-- How rich each sector is changes with distance. The multipliers average 1 at every distance, so
-- each ring holds as much ore as on the standard map. The thin sectors are cheap ground to clear
-- for building.
return {
    name = 'Riches',
    settings = {
        main_ores = Factory.default()
            :richness(Radial.richness(1.53, 0.30), 'iron-ore')
            :richness(Radial.richness(0.78, 1.65), 'copper-ore')
            :richness(Radial.richness(0.69, 1.05), 'coal')
    }
}
