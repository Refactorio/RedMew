
-- Noise tools that were originally developed for diggy, but I have moved to shared folder to make them available to other mods

local Perlin = require 'map_gen.shared.perlin_noise'
local Simplex = require 'map_gen.shared.simplex_noise'

local Noise_tools = {}

-- source of noise for resource generation
-- index determines offset
-- '-1' is reserved for cluster mode
-- compound clusters use as many indexes as needed > 1
local base_seed
function Noise_tools.seeded_noise(surface, x, y, index, sources)
    base_seed = base_seed or surface.map_gen_settings.seed + surface.index + 4000
    local noise = 0
    for _, settings in pairs(sources) do
        settings.type = settings.type or 'perlin'
        settings.offset = settings.offset or 0
        if settings.type == 'zero' then
            noise = noise + 0
        elseif settings.type == 'one' then
            noise = noise + settings.weight * 1
        elseif settings.type == 'perlin' then
            noise = noise + settings.weight * Perlin.noise(x/settings.variance, y/settings.variance,
                        base_seed + 2000*index + settings.offset)
        elseif settings.type == 'simplex' then
            noise = noise + settings.weight * Simplex.d2(x/settings.variance, y/settings.variance,
                        base_seed + 2000*index + settings.offset)
        else
            Debug.print('noise type \'' .. settings.type .. '\' not recognized')
        end

    end
    return noise
end

return Noise_tools
