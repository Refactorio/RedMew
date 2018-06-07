local b = require 'map_gen.shared.builders'

local sand_width = 64
local sand_width_inv = tau / sand_width

local function sand_shape(x, y)
    local h = 6 * math.sin(0.9 * x * sand_width_inv)
    h = h + 3 * math.sin(0.7 * x * sand_width_inv)
    h = h + math.sin(0.33 * x * sand_width_inv)
    return y < h
end

sand_shape = b.change_tile(sand_shape, true, 'sand-1')

local value = b.manhattan_value

local ores = {
    {b.resource(b.full_shape, 'iron-ore', value(250, 1)), 6},
    {b.resource(b.full_shape, 'copper-ore', value(250, 1)), 4},
    {b.resource(b.full_shape, 'stone', value(250, 1)), 1},
    {b.resource(b.full_shape, 'coal', value(250, 1)), 1}
}

uranium_ore = b.resource(b.full_shape, 'uranium-ore', value(50, 0.25))

local total_weights = {}
local t = 0
for _, v in ipairs(ores) do
    t = t + v[2]
    table.insert(total_weights, t)
end

local function do_ores(x, y, world)
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

local water_width = 64
local water_width_inv = tau / water_width

local function water_shape(x, y)
    local h = 6 * math.sin(1.1 * x * water_width_inv)
    h = h + 3 * math.sin(0.74 * x * water_width_inv)
    h = h + math.sin(0.3 * x * water_width_inv)
    return y < h
end

water_shape = b.change_tile(water_shape, true, 'water')

local oil = b.resource(b.full_shape, 'crude-oil', value(500000, 2500))
local function do_oil(x, y, world)
    if math.random(16384) == 1 then
        local e = oil(x, y, world)
        e.always_place = true
        return e
    end
end

water_shape = b.apply_entity(water_shape, do_oil)

grass = b.tile('grass-1')

local bounds = b.line_x(320)

local map = b.any {b.translate(water_shape, 64, -32), sand_shape, grass}

map = b.choose(bounds, map, b.empty_shape)

map = b.translate(map, 0, -64)

return map
