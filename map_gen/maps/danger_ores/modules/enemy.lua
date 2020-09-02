local Perlin = require 'map_gen.shared.perlin_noise'
local math = require 'utils.math'
local seed_provider = require 'map_gen.maps.danger_ores.modules.seed_provider'

local sqrt = math.sqrt
local max = math.max
local min = math.min
local ceil = math.ceil
local perlin_noise = Perlin.noise
local random = math.random

return function(config, shared_globals)
    local worm_names =
        config.worm_names or {'small-worm-turret', 'medium-worm-turret', 'big-worm-turret', 'behemoth-worm-turret'}
    local spawner_names = config.spawner_names or {'biter-spawner', 'spitter-spawner'}
    local factor = config.enemy_factor or 10 / (768 * 32)
    local max_chance = config.enemy_max_chance or 1 / 6
    local scale_factor = config.enemy_scale_factor or 32
    local seed = config.enemy_seed or seed_provider()

    local sf = 1 / scale_factor
    local m = 1 / 850

    return function(x, y, world)
        if shared_globals.biters_disabled then
            return nil
        end

        local d = sqrt(world.x * world.x + world.y * world.y)

        if d < 64 then
            return nil
        end

        local threshold = 1 - d * m
        threshold = max(threshold, 0.35)

        x, y = x * sf, y * sf
        if perlin_noise(x, y, seed) <= threshold then
            return
        end

        if random(8) == 1 then
            local lvl
            if d < 400 then
                lvl = 1
            elseif d < 650 then
                lvl = 2
            elseif d < 900 then
                lvl = 3
            else
                lvl = 4
            end

            local chance = min(max_chance, d * factor)

            if random() < chance then
                local worm_id
                if d > 1000 then
                    local power = 1000 / d
                    worm_id = ceil((random() ^ power) * lvl)
                else
                    worm_id = random(lvl)
                end
                return {name = worm_names[worm_id]}
            end
        else
            local chance = min(max_chance, d * factor)
            if random() < chance then
                local spawner_id = random(2)
                return {name = spawner_names[spawner_id]}
            end
        end
    end
end
