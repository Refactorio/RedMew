local perlin = require 'map_gen.shared.perlin_noise'
local Global = require 'utils.global'

local seed

Global.register_init(
    {},
    function(tbl)
        tbl.seed = math.random(10, 10000)
    end,
    function(tbl)
        seed = tbl.seed
    end
)

return function(x, y)
    local wiggle = 50 + perlin.noise((x * 0.005), (y * 0.005), seed + 71) * 60
    local terrain_A = perlin.noise((x * 0.005), (y * 0.005), seed + 19) * wiggle --For determining where water is
    local terrain_sqr = terrain_A * terrain_A --we can use this again to mess with other layers as well

    if terrain_sqr < 50 then --Main water areas
        terrain_A = perlin.noise((x * 0.01), (y * 0.01), seed + 31) * 90 + (wiggle * -0.2) --we only gen this when we consider placing water

        if terrain_A * terrain_A > 40 then --creates random bridges over the water by overlapping with another noise layer
            return 'water'
        end
    end

    return true
end
