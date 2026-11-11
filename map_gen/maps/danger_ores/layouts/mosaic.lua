local Factory = require 'map_gen.maps.danger_ores.config.main_ores_factory'
local Layouts = require 'map_gen.maps.danger_ores.modules.layouts'

return {
    name = 'Mosaic',
    settings = {
        main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_mosaic',
        -- Coal is pure, for the lines; iron and copper are the usual mixes, stone mixed in.
        main_ores = Factory.default():change_mix({{'coal', 1}}, 'coal'),
        main_ores_rotate = Layouts.NONE
    }
}
