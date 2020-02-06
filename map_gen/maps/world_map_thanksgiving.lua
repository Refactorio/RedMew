-- Map by Jayefuu & grilledham for Thanksgiving 2018
-- For Thanksgiving themed messages and jokes change line 9 of market.lua to:
-- local market_bonus_message = require 'resources.turkey_messages'

local b = require 'map_gen.shared.builders'
local Random = require 'map_gen.shared.random'
local table = require 'utils.table'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

local ore_seed = 3000

RS.set_map_gen_settings(
    {
        MGSP.ore_oil_none,
        MGSP.cliff_none
    }
)

local world_pic = require 'map_gen.data.presets.world-map'
local map = b.picture(world_pic)

local pic = require 'map_gen.data.presets.turkey_bw'
local turkey = b.picture(pic)
turkey = b.invert(turkey)
local bounds = b.rectangle(pic.width, pic.height)
turkey = b.all {bounds, turkey}

local ham = b.picture(require 'map_gen.data.presets.ham')

ham = b.scale(ham, 64 / 127) --0.5
turkey = b.scale(turkey, 0.2)

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
    shape = b.scale(shape, 0.3)
    shape = b.throttle_world_xy(shape, 1, 5, 1, 5)
    return shape
end

local ores = {
    {weight = 150},
    {transform = non_transform, resource = 'iron-ore', value = value(250, 0.75, 1.2), weight = 16},
    {transform = non_transform, resource = 'copper-ore', value = value(200, 0.75, 1.2), weight = 10},
    {transform = non_transform, resource = 'stone', value = value(125, 0.3, 1.05), weight = 7},
    {transform = non_transform, resource = 'coal', value = value(200, 0.8, 1.075), weight = 8},
    {transform = uranium_transform, resource = 'uranium-ore', value = value(100, 0.3, 1.025), weight = 3},
    {transform = oil_transform, resource = 'crude-oil', value = value(100000, 50, 1.1), weight = 6}
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
            shape = turkey
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
            --local ore_shape = shape

            local x = random_ore:next_int(-24, 24)
            local y = random_ore:next_int(-24, 24)
            ore_shape = b.translate(ore_shape, x, y)

            local ore = b.resource(ore_shape, ore_data.resource, ore_data.value)
            row[c] = ore
        end
    end
end

local start_turkey =
    b.segment_pattern {
    b.resource(
        turkey,
        'iron-ore',
        function()
            return 1000
        end
    ),
    b.resource(
        turkey,
        'copper-ore',
        function()
            return 500
        end
    ),
    b.resource(
        turkey,
        'coal',
        function()
            return 750
        end
    ),
    b.resource(
        turkey,
        'stone',
        function()
            return 300
        end
    )
}

ore_pattern[1][1] = start_turkey

local ore_grid = b.grid_pattern_full_overlap(ore_pattern, 50, 50, 96, 96)

ore_grid = b.translate(ore_grid, -60, -20)

map = b.single_x_pattern(map, world_pic.width)
--map = b.translate(map, -369, 46)
map = b.translate(map, 756.5, 564)

map = b.scale(map, 2, 2)
map = b.apply_entity(map, ore_grid)
return map
