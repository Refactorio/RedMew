-- Factory for the standard danger-ores main-ore configs. Most of them use the same
-- per-ore floor tiles and the same dominant+minor resource mixes, differing only in
-- richness curves, ore order, entry weights or tile skins. This module holds those
-- canonical numbers once; each config composes its entries from here.
local b = require 'map_gen.shared.builders'

local Public = {}

-- Per-ore floor tiles.
local tile_sets = {
    ['iron-ore'] = {'grass-1', 'grass-2', 'grass-3', 'grass-4'},
    ['copper-ore'] = {'red-desert-0', 'red-desert-1', 'red-desert-2', 'red-desert-3'},
    ['coal'] = {'dirt-1', 'dirt-2', 'dirt-3', 'dirt-4', 'dirt-5', 'dirt-6', 'dirt-7'},
    ['stone'] = {'sand-1', 'sand-2', 'sand-3'}
}

-- Dominant + minor mixes as {resource name, ratio weight} pairs, in canonical order.
local mixes = {
    ['iron-ore'] = {{'iron-ore', 75}, {'copper-ore', 13}, {'stone', 7}, {'coal', 5}},
    ['copper-ore'] = {{'iron-ore', 15}, {'copper-ore', 70}, {'stone', 10}, {'coal', 5}},
    ['coal'] = {{'iron-ore', 18}, {'copper-ore', 9}, {'stone', 8}, {'coal', 65}},
    ['stone'] = {{'iron-ore', 25}, {'copper-ore', 10}, {'stone', 60}, {'coal', 5}},
    -- the coal-heavier mix used by the X-Cross family and Poor Man's Coal Fields
    ['coal-rich'] = {{'iron-ore', 14}, {'copper-ore', 6}, {'stone', 10}, {'coal', 70}}
}
Public.mixes = mixes

local function copy_array(array)
    local copy = {}
    for i, v in ipairs(array) do
        copy[i] = v
    end
    return copy
end

-- Fresh copy per call: the runtime must never share mutable tables between entries.
function Public.tiles(ore_name)
    return copy_array(tile_sets[ore_name])
end

-- Build a ratios table from a mix. make_resource(resource_name) -> resource shape.
function Public.ratios(mix_name, make_resource)
    local ratios = {}
    for i, mix in ipairs(mixes[mix_name]) do
        ratios[i] = {resource = make_resource(mix[1]), weight = mix[2]}
    end
    return ratios
end

-- The common case: plain full-shape resources with one richness curve.
function Public.full_shape_resource(value)
    return function(resource_name)
        return b.resource(b.full_shape, resource_name, value)
    end
end

-- One main-ore entry. params: name (required), start (required), and either value or
-- make_resource; mix (defaults to name), tiles (defaults to the ore's tile set) and
-- weight (defaults to 1) optional.
function Public.entry(params)
    local name = params.name
    local make_resource = params.make_resource
    if not make_resource then
        assert(params.value, 'main_ores_factory.entry: either value or make_resource is required')
        make_resource = Public.full_shape_resource(params.value)
    end
    return {
        name = name,
        tiles = params.tiles or Public.tiles(name),
        start = params.start,
        weight = params.weight or 1,
        ratios = Public.ratios(params.mix or name, make_resource)
    }
end

-- A whole main-ores config in one call. ores is an array of ore names or per-entry
-- params tables; start/value/weight/tiles/make_resource act as defaults for every entry.
function Public.main_ores(params)
    local config = {}
    for i, ore in ipairs(params.ores) do
        if type(ore) == 'string' then
            ore = {name = ore}
        end
        config[i] = Public.entry {
            name = ore.name,
            mix = ore.mix,
            tiles = ore.tiles or (params.tiles and copy_array(params.tiles)),
            start = ore.start or params.start,
            value = ore.value or params.value,
            weight = ore.weight or params.weight,
            make_resource = ore.make_resource or params.make_resource
        }
    end
    return config
end

return Public
