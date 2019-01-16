local b = require 'map_gen.shared.builders'
local perlin = require 'map_gen.shared.perlin_noise'
local Global = require 'utils.global'
local math = require 'utils.math'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'
local table = require 'utils.table'

local sand_width = 512
local sand_width_inv = math.tau / sand_width
local water_width = 233
local water_width_inv = math.tau / water_width

--perlin options
local noise_variance = 0.025 --The lower this number the smoother the curve is gonna be
local noise_level = 15 --Factor for the magnitude of the curve

local sand_noise_level = noise_level * 0.9
local water_noise_level = noise_level * 1.35

-- Leave nil and they will be set based on the map seed.
local perlin_seed_1 = nil
local perlin_seed_2 = nil

RS.set_map_gen_settings(
    {
        MGSP.ore_oil_none,
        MGSP.cliff_none
    }
)

Global.register_init(
    {},
    function(tbl)
        local seed = RS.get_surface().map_gen_settings.seed
        tbl.perlin_seed_1 = perlin_seed_1 or seed
        tbl.perlin_seed_2 = perlin_seed_2 or seed * 2
    end,
    function(tbl)
        perlin_seed_1 = tbl.perlin_seed_1
        perlin_seed_2 = tbl.perlin_seed_2
    end
)

local function sand_shape(x, y)
    local p = perlin.noise(x * noise_variance, y * noise_variance, perlin_seed_1) * sand_noise_level
    p = p + math.sin(x * sand_width_inv) * 15
    return p > y
end

local function water_shape(x, y)
    local p = perlin.noise(x * noise_variance, y * noise_variance, perlin_seed_2) * water_noise_level
    p = p + math.sin(x * water_width_inv + 179) * 15
    return p > y
end

sand_shape = b.change_tile(sand_shape, true, 'sand-1')

local value = b.manhattan_value

local ores = {
    {b.resource(b.full_shape, 'iron-ore', value(125, 0.5)), 6},
    {b.resource(b.full_shape, 'copper-ore', value(125, 0.5)), 4},
    {b.resource(b.full_shape, 'stone', value(125, 0.25)), 1},
    {b.resource(b.full_shape, 'coal', value(250, 0.25)), 1}
}

local start_coal = b.resource(b.full_shape, 'coal', value(500, 0.25))

local uranium_ore = b.resource(b.full_shape, 'uranium-ore', value(50, 0.25))

local total_weights = {}
local t = 0
for _, v in ipairs(ores) do
    t = t + v[2]
    table.insert(total_weights, t)
end

local function do_ores(x, y, world)
    if x > -4 and x < 5 then
        return start_coal(x, y, world)
    end

    if (x > 512 or x < -512) and (math.floor(x / 32) % 16 == 0) then
        return uranium_ore(x, y, world)
    else
        local i = math.random(t)

        local index = table.binary_search(total_weights, i)
        if (index < 0) then
            index = bit32.bnot(index)
        end

        local ore = ores[index][1]

        return ore(x, y, world)
    end
end

sand_shape = b.apply_entity(sand_shape, do_ores)

water_shape = b.change_tile(water_shape, true, 'water')

local oil = b.resource(b.full_shape, 'crude-oil', value(300000, 2000))
local function do_oil(x, y, world)
    if math.random(16384) == 1 then
        local e = oil(x, y, world)
        e.always_place = true
        return e
    end
end

water_shape = b.apply_entity(water_shape, do_oil)

local grass = b.tile('grass-1')

local bounds = b.line_x(384)

local map = b.any {b.translate(water_shape, 64, -48), sand_shape, grass}

map = b.fish(map, 0.0025)

map = b.choose(bounds, map, b.empty_shape)

map = b.translate(map, 0, -64)

return map
