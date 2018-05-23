local perlin = require 'map_gen.shared.perlin_noise'
local Event = require 'utils.event'

local function init()
    global.terrain_seed_A = math.random(10, 10000)
    global.terrain_seed_B = math.random(10, 10000)
end

Event.on_init(init)

return function(x, y, world)
    local wiggle = 50 + perlin:noise((x * 0.005), (y * 0.005), global.terrain_seed_A + 71) * 60
    local terrain_A = perlin:noise((x * 0.005), (y * 0.005), global.terrain_seed_A + 19) * wiggle --For determining where water is
    local terrain_sqr = terrain_A * terrain_A --we can use this again to mess with other layers as well

    if terrain_sqr < 50 then --Main water areas
        terrain_A = perlin:noise((x * 0.01), (y * 0.01), global.terrain_seed_A + 31) * 90 + (wiggle * -0.2) --we only gen this when we consider placing water

        if terrain_A * terrain_A > 40 then --creates random bridges over the water by overlapping with another noise layer
            return 'water'
        end
    end

    return true
end
