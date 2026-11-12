local Factory = require 'map_gen.maps.danger_ores.config.main_ores_factory'
local Layouts = require 'map_gen.maps.danger_ores.modules.layouts'

return {
    name = 'Mosaic',
    settings = {
        main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_mosaic',
        -- Coal is pure, for the lines; iron and copper are the usual mixes, stone mixed in.
        main_ores = Factory.default():change_mix({{'coal', 1}}, 'coal'),
        -- {ore, weight near spawn, weight far out}: mostly iron close in, more copper where the
        -- rockets get built. Coal draws the lines, and is the odd field too.
        main_ores_mosaic = {
            inks = {{'iron-ore', 60, 30}, {'copper-ore', 32, 62}, {'coal', 8, 8}}
        },
        main_ores_rotate = Layouts.NONE
    }
}
