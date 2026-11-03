local Factory = require 'map_gen.maps.danger_ores.config.main_ores_factory'
local Radial = require 'map_gen.maps.danger_ores.layouts.radial'

-- Petals and Riches each make the whole change; Bloom goes halfway on each: size times richness
-- gives the same ore at every distance as either, so sectors bend half as much as on Petals and
-- are half as lean or rich as on Riches.
return {
    name = 'Bloom',
    settings = {
        main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_radial',
        main_ores_radial = {
            from = Radial.FROM,
            to = Radial.TO,
            inner = {['iron-ore'] = 42, ['copper-ore'] = 30, coal = 28},
            outer = {['iron-ore'] = 19, ['copper-ore'] = 45, coal = 36}
        },
        -- Two of each sector: the sizes change half as much as on Petals, so wider sectors stay
        -- spokes.
        main_ores_split_count = 2,
        main_ores = Factory.default()
            :richness(Radial.richness(1.21, 0.53), 'iron-ore')
            :richness(Radial.richness(0.87, 1.22), 'copper-ore')
            :richness(Radial.richness(0.82, 0.97), 'coal')
    }
}
