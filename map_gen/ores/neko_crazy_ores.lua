local perlin = require 'map_gen.shared.perlin_noise'
local Event = require 'utils.event'
local RS = require 'map_gen.shared.redmew_surface'

local random_ores = {'iron-ore', 'coal', 'copper-ore', 'stone', 'uranium-ore'}
local random_dense = {1.6, 0.8, 1, 0.6, 0.5} --ore density reference

local function run_ores_module_setup()
    local seed = RS.get_surface().map_gen_settings.seed
    if not global.ores_seed_A then
        global.ores_seed_A = seed
    end
    if not global.ores_seed_B then
        global.ores_seed_B = seed * 2
    end
end

Event.on_init(run_ores_module_setup)

return function(x, y, world)
    local d_sq = world.x * world.x + world.y * world.y
    if d_sq < 9216 then
        return
    end

    local distance_bonus = 100 + 0.4 * d_sq ^ 2.4 -- d ^ 1.2

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
            return {name = 'crude-oil', amount = 5000 + math.floor(distance_bonus) * 500}
        end
    end
end
