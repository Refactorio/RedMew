local perlin = require 'map_gen.shared.perlin_noise'

-- list of {x, y, ore_type, size, richness, rng_seed}
local ctrs = {
    {1, -15, 'iron-ore', 0.3, 400, 113},
    {15, 15, 'copper-ore', 0.3, 400, 80},
    {4, 21, 'coal', 0.25, 640, 31},
    {10, 0, 'stone', 0.5, 100, 17},
    {-17, 7, 'uranium-ore', 0.6, 100, 203}
}

local function harmonic(x, y)
    local max_idx = 0
    local max = -1
    local richness = 0
    for i in ipairs(ctrs) do
        local noise = perlin.noise(x / 32, y / 32, ctrs[i][6])
        local h_coeff =
            1 /
            (1 +
                .05 *
                    math.sqrt(
                        (x / 32 - ctrs[i][1]) * (x / 32 - ctrs[i][1]) + (y / 32 - ctrs[i][2]) * (y / 32 - ctrs[i][2])
                    ))
        if noise > max and noise > h_coeff * ctrs[i][4] + (1 - h_coeff) then
            max = noise
            max_idx = i
            richness = (40 * (1 - h_coeff) + 0.5 * h_coeff) * ctrs[i][5]
        end
    end
    return max, max_idx, richness
end

return function(_, _, world)
    if math.abs(world.x / 32) < 3 and math.abs(world.y / 32) < 3 then
        return
    end

    local entities = world.surface.find_entities_filtered {position = {world.x + 0.5, world.y + 0.5}, type = 'resource'}
    for _, e in ipairs(entities) do
        if e.name ~= 'crude-oil' then
            e.destroy()
        end
    end

    local max, max_idx, richness = harmonic(world.x, world.y)

    if -1 ~= max then
        return {name = ctrs[max_idx][3], amount = richness}
    end
end
