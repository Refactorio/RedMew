local Perlin = require 'map_gen.shared.perlin_noise'
local seed_provider = require 'map_gen.maps.danger_ores.modules.seed_provider'

local perlin_noise = Perlin.noise

return function(config)
    local scale = config.dense_patches_scale or 1 / 48
    local threshold = config.dense_patches_threshold or 0.5
    local multiplier = config.dense_patches_multiplier or 50
    local seed = config.dense_patches_seed or seed_provider()

    return function(x, y, entity)
        x, y = x * scale, y * scale
        local noise = perlin_noise(x, y, seed)
        if noise > threshold then
            entity.amount = entity.amount * multiplier
        end
    end
end
