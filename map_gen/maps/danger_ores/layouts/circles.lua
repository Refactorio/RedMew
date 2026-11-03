return {
    name = 'Circles',
    settings = {
        circle_thickness = 16, -- Thickness of the rings at weight 1
        circle_grow_factor = 768, -- How much distance before the thickness doubles.
        main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_circles'
    }
}
