local Perlin = require 'map_gen.shared.perlin_noise'
local math = require 'utils.math'
local seed_provider = require 'map_gen.maps.danger_ores.modules.seed_provider'

local perlin_noise = Perlin.noise
local random = math.random

local trees = {
    'tree-01',
    'tree-02',
    'tree-02-red',
    'tree-03',
    'tree-04',
    'tree-05',
    'tree-06',
    'tree-06-brown',
    'tree-07',
    'tree-08',
    'tree-08-brown',
    'tree-08-red',
    'tree-09',
    'tree-09-brown',
    'tree-09-red'
}

local trees_count = #trees

return function(config)
    local scale = config.trees_scale or 1 / 64
    local threshold = config.trees_threshold or -0.25
    local chance = config.trees_chance or 0.125
    local seed = config.trees_seed or seed_provider()

    return function(x, y)
        local tree_noise = perlin_noise(x * scale, y * scale, seed)
        if tree_noise > threshold or random() > chance then
            return nil
        end

        return {name = trees[random(trees_count)]}
    end
end
