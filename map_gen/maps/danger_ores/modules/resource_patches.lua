local Perlin = require 'map_gen.shared.perlin_noise'
local seed_provider = require 'map_gen.maps.danger_ores.modules.seed_provider'
local b = require 'map_gen.shared.builders'

local perlin_noise = Perlin.noise

return function(config)
    local resource_patches = config.resource_patches_config

    local entities = {}

    for _, data in pairs(resource_patches) do
        local scale = data.scale
        local threshold = data.threshold
        local resource = data.resource
        local seed = data.seed or seed_provider()

        local function entity_shape(x, y, world)
            x, y = x * scale, y * scale
            local noise = perlin_noise(x, y, seed)

            if noise > threshold then
                return resource(x, y, world)
            end

            return nil
        end

        entities[#entities + 1] = entity_shape
    end

    return b.any(entities)
end
