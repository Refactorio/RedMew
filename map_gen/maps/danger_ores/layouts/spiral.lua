local Layouts = require 'map_gen.maps.danger_ores.modules.layouts'

return {
    name = 'Spiral',
    settings = {
        main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_spiral',
        main_ores = require 'map_gen.maps.danger_ores.config.vanilla_ores_landfill',
        main_ores_rotate = Layouts.NONE,
        spawn_tile = 'landfill'
    }
}
