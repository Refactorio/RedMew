local b = require 'map_gen.shared.builders'
local Random = require 'map_gen.shared.random'
local table = require 'utils.table'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

local degrees = require "utils.math".degrees

local ore_seed = 3000

RS.set_map_gen_settings(
    {
        MGSP.ore_oil_none,
        MGSP.cliff_none
    }
)

local wave = b.sine_wave(64, 16, 4)

local waves = b.single_y_pattern(wave, 64)

local bounds = b.rectangle(192, 192)
local wave_island = b.choose(bounds, waves, b.empty_shape)

local wave_island2 = b.rotate(wave_island, degrees(90))

local pattern = {
    {wave_island, wave_island2},
    {wave_island2, wave_island}
}

local wave_islands = b.grid_pattern(pattern, 2, 2, 192, 192)

local wave2 = b.sine_wave(64, 8, 2)
local connecting_wave = b.any {wave2, b.rotate(wave2, degrees(90))}
local connecting_waves = b.single_pattern(connecting_wave, 192, 192)
connecting_waves = b.translate(connecting_waves, 64, 64)

wave_islands = b.any {wave_islands, connecting_waves}

wave_islands = b.change_tile(wave_islands, false, 'deepwater')

wave_islands = b.rotate(wave_islands, degrees(45))

local map = b.change_map_gen_collision_tile(wave_islands, 'water-tile', 'grass-1')
map = b.scale(map, 2)

local pig = b.picture(require 'map_gen.data.presets.pig')
local ham = b.picture(require 'map_gen.data.presets.ham')

pig = b.scale(pig, 64 / 320)
ham = b.scale(ham, 64 / 127)

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

local ores = {
    {weight = 150},
    {transform = non_transform, resource = 'iron-ore', value = value(500, 0.75, 1.2), weight = 16},
    {transform = non_transform, resource = 'copper-ore', value = value(400, 0.75, 1.2), weight = 10},
    {transform = non_transform, resource = 'stone', value = value(250, 0.3, 1.05), weight = 3},
    {transform = non_transform, resource = 'coal', value = value(400, 0.8, 1.075), weight = 8},
    {transform = uranium_transform, resource = 'uranium-ore', value = value(200, 0.3, 1.025), weight = 3},
    {transform = oil_transform, resource = 'crude-oil', value = value(180000, 50, 1.1), weight = 6}
}

local total_ore_weights = {}
local ore_t = 0
for _, v in ipairs(ores) do
    ore_t = ore_t + v.weight
    table.insert(total_ore_weights, ore_t)
end

local random_ore = Random.new(ore_seed, ore_seed * 2)
local ore_pattern = {}

for r = 1, 50 do
    local row = {}
    ore_pattern[r] = row
    local even_r = r % 2 == 0
    for c = 1, 50 do
        local even_c = c % 2 == 0
        local shape
        if even_r == even_c then
            shape = pig
        else
            shape = ham
        end

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
            local ore_shape = transform(shape)

            local x = random_ore:next_int(-24, 24)
            local y = random_ore:next_int(-24, 24)
            ore_shape = b.translate(ore_shape, x, y)

            local ore = b.resource(ore_shape, ore_data.resource, ore_data.value)
            row[c] = ore
        end
    end
end

local start_pig =
    b.segment_pattern {
    b.resource(
        pig,
        'iron-ore',
        function()
            return 1000
        end
    ),
    b.resource(
        pig,
        'copper-ore',
        function()
            return 500
        end
    ),
    b.resource(
        pig,
        'coal',
        function()
            return 750
        end
    ),
    b.resource(
        pig,
        'stone',
        function()
            return 300
        end
    )
}

ore_pattern[1][1] = start_pig

local ore_grid = b.grid_pattern_full_overlap(ore_pattern, 50, 50, 96, 96)

ore_grid = b.translate(ore_grid, -50, 64)

map = b.apply_entity(map, ore_grid)
map = b.fish(map, 0.0025)

return map
