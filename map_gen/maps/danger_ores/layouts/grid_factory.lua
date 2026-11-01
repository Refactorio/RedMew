local B = require 'map_gen.shared.builders'

return {
    name = 'Grid Factory',
    settings = {
        main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_grid_factory',
        main_ores = require 'map_gen.maps.danger_ores.config.vanilla_ores_landfill',
        spawn_tile = 'orange-refined-concrete',
        spawn_shape = B.circle(20),
        start_ore_shape = B.circle(40),
        no_resource_patch_shape = B.circle(80)
    }
}
