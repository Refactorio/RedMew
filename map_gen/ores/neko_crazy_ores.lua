local perlin = require 'map_gen.shared.perlin_noise'
local Event = require 'utils.event'

local random_ores = {'iron-ore', 'coal', 'copper-ore', 'stone', 'uranium-ore'}
local random_dense = {1.15, 0.8, 1, 0.9, 0.5} --ore density reference

local function run_ores_module_setup()
    if not global.ores_seed_A then
        global.ores_seed_A = math.random(10, 10000)
    end
    if not global.ores_seed_B then
        global.ores_seed_B = math.random(10, 10000)
    end
end

Event.on_init(run_ores_module_setup)

return function(x, y, world)
    local pos = {world.x + 0.5, world.y + 0.5}

    local entities = world.surface.find_entities_filtered {position = pos, type = 'resource'}
    for _, e in ipairs(entities) do
        e.destroy()
    end

    local distance_bonus = 200 + math.sqrt(world.x * world.x + world.y * world.y) * 0.2

    local wiggle = 100 + perlin.noise((x * 0.005), (y * 0.005), global.ores_seed_A + 41) * 60
    local Ores_A = perlin.noise((x * 0.01), (y * 0.01), global.ores_seed_B + 57) * wiggle

    if Ores_A > 35 then --we place ores
        local Ores_B = perlin.noise((x * 0.02), (y * 0.02), global.ores_seed_B + 13) * wiggle
        local a = 5
        --
        if Ores_A < 76 then
            a = math.floor(Ores_A * 0.75 + Ores_B * 0.5) % 4 + 1
        end --if its not super high we place normal ores
        --
        local res_amount = distance_bonus
        res_amount = math.floor(res_amount * random_dense[a])
        --

        return {name = random_ores[a], amount = res_amount}
    elseif Ores_A < -60 then
        if math.random(1, 200) == 1 then
            return {name = 'crude-oil', amount = math.random(5000, 20000) + math.floor(distance_bonus) * 1500}
        end
    end
end
