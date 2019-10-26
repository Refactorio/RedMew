local b = require 'map_gen.shared.builders'
local Random = require 'map_gen.shared.random'
local table = require 'utils.table'

local Map_gen_config = (require 'map_gen.maps.space_race.config').map_gen

local seed1 = 17000
local seed2 = seed1 * 2

local width_2 = Map_gen_config.width_2

local function value(base, mult, pow)
    return function(x, y)
        local d = math.sqrt(x * x + y * y)
        return base + mult * d ^ pow
    end
end

local function non_transform(shape)
    return shape
end

local function uranium_transform(shape)
    return b.scale(shape, 0.5)
end

local function oil_transform(shape)
    shape = b.scale(shape, 0.5)
    shape = b.throttle_world_xy(shape, 1, 5, 1, 5)
    return shape
end

local function water_transform(shape)
    shape = b.change_tile(shape, true, 'water')
    return shape
end

local ores = {
    {weight = 50},
    {transform = non_transform, resource = 'iron-ore', value = value(500, 0.75, 1.2), weight = 16},
    {transform = non_transform, resource = 'copper-ore', value = value(400, 0.75, 1.2), weight = 10},
    {transform = non_transform, resource = 'stone', value = value(250, 0.3, 1.05), weight = 3},
    {transform = non_transform, resource = 'coal', value = value(400, 0.8, 1.075), weight = 8},
    {transform = uranium_transform, resource = 'uranium-ore', value = value(200, 0.3, 1.025), weight = 3},
    {transform = oil_transform, resource = 'crude-oil', value = value(180000, 50, 1.1), weight = 6},
    {transform = water_transform, weight = 100}
}

local total_ore_weights = {}
local ore_t = 0
for _, v in ipairs(ores) do
    ore_t = ore_t + v.weight
    table.insert(total_ore_weights, ore_t)
end

local random_ore = Random.new(seed1, seed2)
local ore_pattern = {}
local water_pattern = {}

local p_cols = width_2
local p_rows = 32

for r = 1, p_rows do
    local row = {}
    ore_pattern[r] = row
    local water_row = {}
    water_pattern[r] = water_row
    for c = 1, p_cols do
        local i = random_ore:next_int(1, ore_t)
        local index = table.binary_search(total_ore_weights, i)
        if (index < 0) then
            index = bit32.bnot(index)
        end
        local ore_data = ores[index]

        local transform = ore_data.transform
        if not transform then
            row[c] = b.no_entity
        else
            local shape = b.circle(8)
            local ore_shape = transform(shape)

            local x = random_ore:next_int(-16, 16)
            local y = random_ore:next_int(-16, 16)
            ore_shape = b.translate(ore_shape, x, y)
            local resource = ore_data.resource

            if not resource then
                water_row[c] = ore_shape
                row[c] = b.no_entity
            else
                ore_shape = b.resource(ore_shape, resource, ore_data.value, true)
                row[c] = ore_shape
            end
        end
    end
end

local mirrored_ore = b.grid_pattern_full_overlap(ore_pattern, p_cols, p_rows, 48, 48)
local mirrored_water = b.grid_pattern_full_overlap(water_pattern, p_cols, p_rows, 48, 48)

return {mirrored_ore, mirrored_water}
