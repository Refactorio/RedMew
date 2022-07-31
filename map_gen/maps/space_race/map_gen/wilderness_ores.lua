local b = require 'map_gen.shared.builders'
local Random = require 'map_gen.shared.random'
local table = require 'utils.table'
local Global = require 'utils.global'
local RS = require 'map_gen.shared.redmew_surface'

local Map_gen_config = (require 'map_gen.maps.space_race.config').map_gen

local seed = nil -- set to number to force seed
local seed_2 = nil -- set to number to force seed

local width_2 = Map_gen_config.width_2

local pic = require 'map_gen.data.presets.death'
pic = b.decompress(pic)

local death_shape = b.picture(pic)
death_shape = b.scale(death_shape, 0.075, 0.075)

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
    return b.scale(shape, 0.75)
end

local function oil_transform(shape)
    shape = b.throttle_xy(shape, 1, 5, 1, 5)
    return shape
end

local function water_transform(shape)
    shape = b.change_tile(shape, true, 'water')
    return shape
end

local ores = {
    {weight = 200},
    {transform = non_transform, resource = 'iron-ore', value = value(500, 0.75, 1.2), weight = 12},
    {transform = non_transform, resource = 'copper-ore', value = value(400, 0.75, 1.2), weight = 10},
    {transform = non_transform, resource = 'stone', value = value(250, 0.3, 1.05), weight = 3},
    {transform = non_transform, resource = 'coal', value = value(400, 0.8, 1.075), weight = 8},
    {transform = uranium_transform, resource = 'uranium-ore', value = value(100, 0.3, 1.015), weight = 3},
    {transform = oil_transform, resource = 'crude-oil', value = value(180000, 50, 1.1), weight = 6},
    {transform = water_transform, weight = 20}
}

local total_ore_weights = {}
local ore_t = 0
for _, v in ipairs(ores) do
    ore_t = ore_t + v.weight
    table.insert(total_ore_weights, ore_t)
end

local random_ore = Random.new(seed, seed_2)
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
            local resource = ore_data.resource

            local ore_shape
            if resource == 'crude-oil' then
                ore_shape = transform(b.rectangle(24, 24))
            else
                ore_shape = transform(death_shape)
            end

            local x = random_ore:next_int(-16, 16)
            local y = random_ore:next_int(-16, 16)
            ore_shape = b.translate(ore_shape, x, y)

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

Global.register_init(
    {},
    function(tbl)
        tbl.seed = seed or RS.get_surface().map_gen_settings.seed
        tbl.seed_2 = seed_2 or tbl.seed * 2
    end,
    function(tbl)
        seed = tbl.seed
        seed_2 = tbl.seed_2
    end
)

return {mirrored_ore, mirrored_water}
