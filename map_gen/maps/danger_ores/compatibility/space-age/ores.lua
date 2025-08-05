local b = require 'map_gen.shared.builders'
local math = require 'utils.math'
local table = require 'utils.table'

local random = math.random
local bnot = bit32.bnot
local binary_search = table.binary_search
local value = b.euclidean_value

--- Solid patches
local ratio_value = b.exponential_value(0, 1.4, 1.45)

local iron_ratios = {
    { resource = b.resource(b.full_shape, 'iron-ore',   ratio_value), weight = 80 },
    { resource = b.resource(b.full_shape, 'copper-ore', ratio_value), weight = 13 },
    { resource = b.resource(b.full_shape, 'stone',      ratio_value), weight =  7 },
}

local copper_ratios = {
    { resource = b.resource(b.full_shape, 'iron-ore',   ratio_value), weight = 15 },
    { resource = b.resource(b.full_shape, 'copper-ore', ratio_value), weight = 75 },
    { resource = b.resource(b.full_shape, 'stone',      ratio_value), weight = 10 },
}

local function build_solid_patches(ratios)
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

--- Liquid patches
local full_oil_shape = b.translate(b.throttle_xy(b.full_shape, 3, 6, 3, 6), -1, -1)
full_oil_shape = b.use_world_as_local(full_oil_shape)
local oil_shape = b.throttle_world_xy(b.full_shape, 1, 6, 1, 6)

local function build_liquid_patches(name, data)
    return {
        scale = data.scale,
        threshold = data.t,
        resource = b.any{ b.resource(oil_shape, name, value(data.base, data.mult)), full_oil_shape }
    }
end

return {
    { scale = 1 / 24, threshold = 0.50, resource = build_solid_patches(iron_ratios) },
    { scale = 1 / 24, threshold = 0.50, resource = build_solid_patches(copper_ratios) },
    { scale = 1 / 48, threshold = 0.66, resource = b.resource(b.full_shape, 'tungsten-ore', value(100, 1.5)) },
    { scale = 1 / 24, threshold = 0.66, resource = b.resource(b.full_shape, 'calcite',      value(100, 1.5)) },
    { scale = 1 / 48, threshold = 0.66, resource = b.resource(b.full_shape, prototypes.entity['holmium-ore'] and 'holmium-ore' or 'scrap',  value(100, 1.5)) },
    build_liquid_patches('sulfuric-acid-geyser', { scale = 1/64, t = 0.70, base = 100000, mult = 2500 }),
    build_liquid_patches('lithium-brine',        { scale = 1/32, t = 0.70, base = 100000, mult = 2500 }),
    build_liquid_patches('fluorine-vent',        { scale = 1/32, t = 0.70, base = 100000, mult = 2500 }),
}
