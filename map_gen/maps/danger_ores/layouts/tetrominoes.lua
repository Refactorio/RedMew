local Layouts = require 'map_gen.maps.danger_ores.modules.layouts'

return {
    name = 'Tetrominoes',
    settings = {
        main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_tetrominoes',
        main_ores = require 'map_gen.maps.danger_ores.config.vanilla_ores_stone',
        main_ores_rotate = Layouts.NONE
    }
}
