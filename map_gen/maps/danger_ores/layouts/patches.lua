local Layouts = require 'map_gen.maps.danger_ores.modules.layouts'

return {
    name = 'Patches',
    settings = {
        main_ore_resource_patches_config = require 'map_gen.maps.danger_ores.config.main_ore_resource_patches',
        main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_patches',
        main_ores = require 'map_gen.maps.danger_ores.config.coal',
        main_ores_rotate = Layouts.NONE
    }
}
