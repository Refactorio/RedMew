local b = require 'map_gen.shared.builders'
local Perlin = require 'map_gen.shared.perlin_noise'
local table = require 'utils.table'
local Debug = require 'utils.debug'

local random = math.random
local floor = math.floor
local value = b.euclidean_value
local binary_search = table.binary_search
local bnot = bit32.bnot
local perlin_noise = Perlin.noise

local mixed_ores = true

local tile_scale = 1 / 64
local spawn_zone = b.circle(85)

local density_scale = 1 / 48
local density_threshold = 0.5
local density_multiplier = 50

local ores = {
    ['angels-ore1'] = { -- Saphirite
        ['tiles'] = {
            [1] = 'grass-1',
            [2] = 'grass-2',
            [3] = 'grass-3',
            [4] = 'grass-4'
        },
        ['start'] = value(125, 0),
        ['non_mixed_value'] = value(0, 0.5),
        ['weight'] = 15,
        ['ratios'] = {}
    },
    ['angels-ore2'] = { -- Jivolite
        ['tiles'] = {
          [1] = 'dirt-1',
          [2] = 'dirt-2',
          [3] = 'dirt-3'
        },
        ['start'] = value(125, 0),
        ['non_mixed_value'] = value(0, 0.5),
        ['weight'] = 10,
        ['ratios'] = {}
    },
    ['angels-ore3'] = { -- Stiratite
        ['tiles'] = {
            [1] = 'red-desert-0',
            [2] = 'red-desert-1',
            [3] = 'red-desert-2',
            [4] = 'red-desert-3'
        },
        ['start'] = value(125, 0),
        ['non_mixed_value'] = value(0, 0.5),
        ['weight'] = 10,
        ['ratios'] = {}
    },
    ['angels-ore4'] = { -- crotinnium
        ['tiles'] = {
            [1] = 'grass-3',
            [2] = 'grass-4'
        },
        ['start'] = value(125, 0),
        ['non_mixed_value'] = value(0, 0.5),
        ['weight'] = 10,
        ['ratios'] = {}
    },
    ['angels-ore5'] = { -- rubyte
        ['tiles'] = {
            [1] = 'grass-1',
            [2] = 'grass-2'
        },
        ['start'] = value(125, 0),
        ['non_mixed_value'] = value(0, 0.5),
        ['weight'] = 10,
        ['ratios'] = {}
    },
    ['angels-ore6'] = { -- bobmonium-ore
        ['tiles'] = {
            [1] = 'sand-1',
            [2] = 'sand-2',
            [3] = 'sand-3'
        },
        ['start'] = value(125, 0),
        ['non_mixed_value'] = value(0, 0.5),
        ['weight'] = 10,
        ['ratios'] = {}
    },
    ['coal'] = {
        ['tiles'] = {
            [1] = 'dirt-5',
            [2] = 'dirt-6',
            [3] = 'dirt-7'
        },
        ['start'] = value(125, 0),
        ['non_mixed_value'] = value(0, 0.5),
        ['weight'] = 10,
        ['ratios'] = {}
    }
}

-- Build ratios based on global weights
local ratio_mixed = 80 -- % purity in the ore

local oil_scale = 1 / 64
local oil_threshold = 0.6
local oil_shape = b.throttle_world_xy(b.full_shape, 1, 7, 1, 7)
local oil_resource = b.resource(oil_shape, 'crude-oil', value(250000, 150))

local fissure_scale = 1 / 100
local fissure_threshold = 0.6
local fissure_shape = b.throttle_world_xy(b.full_shape, 1, 7, 1, 7)
local fissure_resource = b.resource(fissure_shape, 'angels-fissure', value(25000, 150))

local gas_well_scale = 1 / 64
local gas_well_threshold = 0.6
local gas_well_shape = b.throttle_world_xy(b.full_shape, 1, 7, 1, 7)
local gas_well_resource = b.resource(gas_well_shape, 'angels-natural-gas', value(25000, 150))

local thorium_scale = 1 / 72
local thorium_threshold = 0.63
local thorium_resource = b.resource(b.full_shape, 'thorium-ore', value(200, 1))

local function init(seed)
    local oil_seed = seed * 2
    local uranium_seed = seed * 3
    local density_seed = seed * 4
    local thorium_seed = seed * 5
    local fissure_seed = seed * 6
    local gas_well_seed = seed * 7


    local function tile_builder(tiles)
        local count = #tiles / 2
        return function(x, y)
            x, y = x * tile_scale, y * tile_scale
            local v = perlin_noise(x, y, seed)
            v = ((v + 1) * count) + 1
            v = floor(v)
            return tiles[v]
        end
    end

    local function ore_builder(ore_name, amount, ratios, weighted)
        local start_ore = b.resource(b.full_shape, ore_name, amount)
        local total = weighted.total
        return function(x, y, world)
            if spawn_zone(x, y) then
                return start_ore(x, y, world)
            end

            local oil_x, oil_y = x * oil_scale, y * oil_scale
            local oil_noise = perlin_noise(oil_x, oil_y, oil_seed)
            if oil_noise > oil_threshold then
                return oil_resource(x, y, world)
            end

            local fissure_x, fissure_y = x * fissure_scale, y * fissure_scale
            local fissure_noise = perlin_noise(fissure_x, fissure_y, fissure_seed)
            if fissure_noise > fissure_threshold then
                return fissure_resource(x, y, world)
            end

            local gas_well_x, gas_well_y = x * gas_well_scale, y * gas_well_scale
            local gas_well_noise = perlin_noise(gas_well_x, gas_well_y, gas_well_seed)
            if gas_well_noise > gas_well_threshold then
                return gas_well_resource(x, y, world)
            end

            local thorium_x, thorium_y = x * thorium_scale, y * thorium_scale
            local thorium_noise = perlin_noise(thorium_x, thorium_y, thorium_seed)
            if thorium_noise > thorium_threshold then
                return thorium_resource(x, y, world)
            end

            local i = random() * total
            local index = binary_search(weighted, i)
            if index < 0 then
                index = bnot(index)
            end

            local resource = ratios[index].resource

            local entity = resource(x, y, world)
            local density_x, density_y = x * density_scale, y * density_scale
            local density_noise = perlin_noise(density_x, density_y, density_seed)

            if density_noise > density_threshold then
                entity.amount = entity.amount * density_multiplier
            end

            entity.enable_tree_removal = false

            return entity
        end
    end

    local function non_mixed_ore_builder(ore_name, amount)
        local resource = b.resource(b.full_shape, ore_name, amount)
        return function(x, y, world)
            if spawn_zone(x, y) then
                return resource(x, y, world)
            end

            local oil_x, oil_y = x * oil_scale, y * oil_scale
            local oil_noise = perlin_noise(oil_x, oil_y, oil_seed)
            if oil_noise > oil_threshold then
                return oil_resource(x, y, world)
            end

            local fissure_x, fissure_y = x * fissure_scale, y * fissure_scale
            local fissure_noise = perlin_noise(fissure_x, fissure_y, fissure_seed)
            if fissure_noise > fissure_threshold then
                return fissure_resource(x, y, world)
            end

            local gas_well_x, gas_well_y = x * gas_well_scale, y * gas_well_scale
            local gas_well_noise = perlin_noise(gas_well_x, gas_well_y, gas_well_seed)
            if gas_well_noise > gas_well_threshold then
                return gas_well_resource(x, y, world)
            end

            local thorium_x, thorium_y = x * thorium_scale, y * thorium_scale
            local thorium_noise = perlin_noise(thorium_x, thorium_y, thorium_seed)
            if thorium_noise > thorium_threshold then
                return thorium_resource(x, y, world)
            end

            local entity = resource(x, y, world)
            local density_x, density_y = x * density_scale, y * density_scale
            local density_noise = perlin_noise(density_x, density_y, density_seed)

            if density_noise > density_threshold then
                entity.amount = entity.amount * density_multiplier
            end

            entity.enable_tree_removal = false

            return entity
        end
    end

    local shapes = {}

    for ore_name, v in pairs(ores) do
        local tiles = v.tiles
        local land = tile_builder(tiles)

        local ore
        if mixed_ores then
            local ratios = {
              {resource = b.resource(b.full_shape, ore_name, value(0, 0.5)), weight = ( ratio_mixed ) }
            }
            local other_ratios = 0
            for ore2_name, v2 in pairs(ores) do
              if ore2_name ~= ore_name then
                other_ratios = other_ratios + v2.weight
              end
            end

            local pos = 0
            for ore2_name, v2 in pairs(ores) do
              Debug.print('Attempting to add ' .. ore2_name .. ' to ratio')
              pos = pos + 1
              if ore2_name ~= ore_name then
                table.insert(ratios, {resource = b.resource(b.full_shape, ore2_name, value(0, 0.5)), weight = ( ( 100 - ratio_mixed)  * ( v2.weight / other_ratios ) ) })
              end
            end

            local weighted = b.prepare_weighted_array(ratios)
            local amount = v.start

            Debug.print('Number of mixed ores in ratio ' .. #ratios)

            ore = ore_builder(ore_name, amount, ratios, weighted)
        else
            local amount = v.non_mixed_value

            ore = non_mixed_ore_builder(ore_name, amount)
        end

        local shape = b.apply_entity(land, ore)
        shapes[#shapes + 1] = {shape = shape, weight = v.weight}
    end

    return shapes
end

return init
