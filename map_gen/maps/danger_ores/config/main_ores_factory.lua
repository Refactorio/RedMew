-- Factory for the standard danger-ores main-ore configs. Most of them use the same
-- per-ore floor tiles and the same dominant+minor resource mixes, differing only in
-- richness curves, ore order, entry weights or tile skins. This module holds those
-- canonical numbers once; each config composes its entries from here.
--
-- Two levels of API:
--   * the low-level table builders (entry / main_ores) for configs with special needs
--   * a fluent API for everything else:
--       Factory.default()                          -- canonical copper/coal/iron
--       Factory.default():add_ore('stone')         -- plus the stone sector
--       Factory.default():change_tiles('landfill') -- reskin every sector
--       Factory.blank():add_ore('omnite')          -- modded worlds from scratch
--     The returned object IS the main_ores array (assign it to map_config.main_ores
--     directly); every method mutates it in place and returns it for chaining.
local b = require 'map_gen.shared.builders'
local table = require 'utils.table'

local deep_copy = table.deep_copy

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
    ['stone'] = {{'iron-ore', 25}, {'copper-ore', 10}, {'stone', 60}, {'coal', 5}}
}
Public.mixes = mixes

-- The canonical richness curves.
local default_start = b.euclidean_value(0, 0.35)
local default_value = b.exponential_value(0, 0.07, 1.45)

-- Fresh copy per call: the runtime must never share mutable tables between entries.
-- Unknown (modded) ores have no canonical tile set and return nil.
function Public.tiles(ore_name)
    local tiles = tile_sets[ore_name]
    return tiles and deep_copy(tiles)
end

-- Build a ratios table from a mix: a canonical mix name, an explicit array of
-- {resource name, weight} pairs, or an unknown ore name (pure self-mix).
-- make_resource(resource_name) -> resource shape.
function Public.ratios(mix, make_resource)
    if type(mix) == 'string' then
        mix = mixes[mix] or {{mix, 1}}
    end
    local ratios = {}
    for i, pair in ipairs(mix) do
        ratios[i] = {resource = make_resource(pair[1]), weight = pair[2]}
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
-- make_resource; mix (defaults to name), tiles (defaults to the ore's tile set; pass
-- false for a tile-less entry) and weight (defaults to 1) optional.
function Public.entry(params)
    local name = params.name
    local make_resource = params.make_resource
    if not make_resource then
        assert(params.value, 'main_ores_factory.entry: either value or make_resource is required')
        make_resource = Public.full_shape_resource(params.value)
    end
    local tiles
    if params.tiles == nil then
        tiles = Public.tiles(name)
    elseif params.tiles then
        tiles = params.tiles
    end
    return {
        name = name,
        tiles = tiles,
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
            tiles = ore.tiles or (params.tiles and deep_copy(params.tiles)),
            start = ore.start or params.start,
            value = ore.value or params.value,
            weight = ore.weight or params.weight,
            make_resource = ore.make_resource or params.make_resource
        }
    end
    return config
end

-- == Fluent API =============================================================

local Fluent = {}

-- {base = b, mult = m} shorthand becomes a euclidean curve (b + m * distance);
-- functions and plain numbers (flat richness) pass through.
local function normalize_start(start)
    if type(start) == 'table' then
        return b.euclidean_value(start.base or start[1] or 0, start.mult or start[2])
    end
    return start
end

-- {base = b, mult = m, pow = p} shorthand becomes an exponential curve
-- (b + m * distance^p); functions pass through.
local function normalize_value(value)
    if type(value) == 'table' then
        return b.exponential_value(value.base or value[1] or 0, value.mult or value[2], value.pow or value[3])
    end
    return value
end

-- Rebuild the array part from the spec. Called after every fluent method, so the
-- object is always a complete, valid main_ores config and method order never matters.
local function rebuild(self)
    local spec = getmetatable(self).spec
    for i = #self, 1, -1 do
        self[i] = nil
    end
    for index, ore in ipairs(spec.ores) do
        local tiles = ore.tiles
        if type(tiles) == 'table' then
            tiles = deep_copy(tiles)
        end
        self[index] = Public.entry {
            name = ore.name,
            mix = ore.mix,
            tiles = tiles,
            start = ore.start ~= nil and ore.start or spec.start,
            value = ore.value or spec.value,
            weight = ore.weight,
            make_resource = ore.make_resource
        }
    end
    return self
end

local function fluent(ores)
    local spec = {start = default_start, value = default_value, ores = ores}
    return rebuild(setmetatable({}, {__index = Fluent, spec = spec}))
end

--- The canonical vanilla config: copper/coal/iron sectors, vanilla curves.
function Public.default()
    return fluent {{name = 'copper-ore'}, {name = 'coal'}, {name = 'iron-ore'}}
end

--- No sectors at all; add them with add_ore. Curves default to the vanilla pair.
function Public.blank()
    return fluent {}
end

--- Append a sector. Canonical ores bring their mix and tiles; unknown (modded) ores
-- default to a pure self-mix and no tiles. opts (all optional): mix (name or
-- {resource, weight} pairs), tiles (array, or false for none), start, value, weight,
-- make_resource.
function Fluent:add_ore(name, opts)
    local ore = {name = name}
    for key, option in pairs(opts or {}) do
        ore[key] = option
    end
    local spec = getmetatable(self).spec
    spec.ores[#spec.ores + 1] = ore
    return rebuild(self)
end

--- Remove every sector called name.
function Fluent:remove_ore(name)
    local spec = getmetatable(self).spec
    for i = #spec.ores, 1, -1 do
        if spec.ores[i].name == name then
            table.remove(spec.ores, i)
        end
    end
    return rebuild(self)
end

--- Patch a sector's options in place: mix, tiles, start, value, weight, make_resource.
function Fluent:update_ore(name, opts)
    local spec = getmetatable(self).spec
    for _, ore in ipairs(spec.ores) do
        if ore.name == name then
            for key, option in pairs(opts) do
                ore[key] = option
            end
        end
    end
    return rebuild(self)
end

--- Change the resource mix of every sector, or just ore_name's. mix: a canonical mix
-- name or an array of {resource name, ratio weight} pairs.
function Fluent:change_mix(mix, ore_name)
    local spec = getmetatable(self).spec
    for _, ore in ipairs(spec.ores) do
        if ore_name == nil or ore.name == ore_name then
            ore.mix = mix
        end
    end
    return rebuild(self)
end

--- Reskin every sector, or just ore_name's. tiles: tile name or array of tile names.
function Fluent:change_tiles(tiles, ore_name)
    if type(tiles) == 'string' then
        tiles = {tiles}
    end
    local spec = getmetatable(self).spec
    for _, ore in ipairs(spec.ores) do
        if ore_name == nil or ore.name == ore_name then
            ore.tiles = tiles
        end
    end
    return rebuild(self)
end

-- Materialize a sector's tile list so it can be edited (defaults live in tile_sets).
local function own_tiles(ore)
    if ore.tiles == nil then
        ore.tiles = Public.tiles(ore.name)
    end
    return ore.tiles
end

--- Append a tile to every sector's list, or just ore_name's.
function Fluent:add_tile(tile, ore_name)
    local spec = getmetatable(self).spec
    for _, ore in ipairs(spec.ores) do
        if ore_name == nil or ore.name == ore_name then
            local tiles = own_tiles(ore)
            if tiles then
                tiles[#tiles + 1] = tile
            else
                ore.tiles = {tile}
            end
        end
    end
    return rebuild(self)
end

--- Remove a tile from every sector's list, or just ore_name's.
function Fluent:remove_tile(tile, ore_name)
    local spec = getmetatable(self).spec
    for _, ore in ipairs(spec.ores) do
        if ore_name == nil or ore.name == ore_name then
            local tiles = own_tiles(ore)
            if tiles then
                table.remove_element(tiles, tile)
            end
        end
    end
    return rebuild(self)
end

--- Set the richness curve -- for one sector, or as the default for every sector
-- without its own: a function, or {base = b, mult = m, pow = p} for an exponential
-- curve b + m * distance^p.
function Fluent:richness(value, ore_name)
    value = normalize_value(value)
    local spec = getmetatable(self).spec
    if ore_name then
        for _, ore in ipairs(spec.ores) do
            if ore.name == ore_name then
                ore.value = value
            end
        end
    else
        spec.value = value
    end
    return rebuild(self)
end

--- Set the start (guaranteed spawn richness) curve -- for one sector, or as the
-- default: a function, a plain number (flat), or {base = b, mult = m} for a euclidean
-- curve b + m * distance.
function Fluent:start_value(start, ore_name)
    start = normalize_start(start)
    local spec = getmetatable(self).spec
    if ore_name then
        for _, ore in ipairs(spec.ores) do
            if ore.name == ore_name then
                ore.start = start
            end
        end
    else
        spec.start = start
    end
    return rebuild(self)
end

--- Set per-sector selection weights from a map of ore name -> weight.
function Fluent:sector_weights(weights)
    local spec = getmetatable(self).spec
    for _, ore in ipairs(spec.ores) do
        if weights[ore.name] then
            ore.weight = weights[ore.name]
        end
    end
    return rebuild(self)
end

return Public
