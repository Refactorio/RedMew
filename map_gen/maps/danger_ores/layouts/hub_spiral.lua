local sqrt = math.sqrt

return {
    name = 'Hub Spiral',
    settings = {
        main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_hub_spiral',
        water_scale = function(x, y)
            local d = sqrt(x * x + y * y)
            return 1 / (24 + (0.1 * d))
        end
    }
}
