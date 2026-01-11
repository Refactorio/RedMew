local Perlin = require 'map_gen.shared.perlin_noise'
local math = require 'utils.math'
local seed_provider = require 'map_gen.maps.danger_ores.modules.seed_provider'

local perlin_noise = Perlin.noise
local random = math.random

local function get_tree_names()
    local tree_names = {}
    for name in pairs(prototypes.get_entity_filtered{{ filter = 'type', type = 'tree' }}) do
        table.insert(tree_names, name)
    end
    return tree_names
end

return function(config)
    local trees = config.tree_names or get_tree_names()
    local scale = config.trees_scale or 1 / 64
    local threshold = config.trees_threshold or -0.25
    local chance = config.trees_chance or 0.125
    local seed = config.trees_seed or seed_provider()
    local trees_count = #trees

    if trees_count == 0 then
        return function()
        end
    end

    return function(x, y)
        local tree_noise = perlin_noise(x * scale, y * scale, seed)
        if tree_noise < threshold or random() < chance then
            return nil
        end

        return {name = trees[random(trees_count)]}
    end
end
