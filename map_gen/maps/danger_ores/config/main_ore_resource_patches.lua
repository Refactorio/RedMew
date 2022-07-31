local b = require 'map_gen.shared.builders'
local math = require 'utils.math'
local table = require 'utils.table'

local random = math.random
local bnot = bit32.bnot
local binary_search = table.binary_search

local ratio_value = b.exponential_value(0, 1.4, 1.45)

local iron_ratios = {
    {resource = b.resource(b.full_shape, 'iron-ore', ratio_value), weight = 80},
    {resource = b.resource(b.full_shape, 'copper-ore', ratio_value), weight = 13},
    {resource = b.resource(b.full_shape, 'stone', ratio_value), weight = 7}
}

local copper_ratios = {
    {resource = b.resource(b.full_shape, 'iron-ore', ratio_value), weight = 15},
    {resource = b.resource(b.full_shape, 'copper-ore', ratio_value), weight = 75},
    {resource = b.resource(b.full_shape, 'stone', ratio_value), weight = 10}
}

local function build_ratio_patches(ratios)
    return function(x, y, world)
        local weighted = b.prepare_weighted_array(ratios)
        local total = weighted.total

        local i = random() * total
        local index = binary_search(weighted, i)
        if index < 0 then
            index = bnot(index)
        end

        local resource = ratios[index].resource
        local entity = resource(x, y, world)

        entity.enable_tree_removal = false

        return entity
    end
end

return {
    {scale = 1 / 24, threshold = 0.5, resource = build_ratio_patches(iron_ratios)},
    {scale = 1 / 24, threshold = 0.5, resource = build_ratio_patches(copper_ratios)}
}
