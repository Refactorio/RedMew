-- Map by grilledham, modified by Jayefuu
-- This variation on grid_islands.lua has 1) Greater island separation 2) 4 not 2 rail tracks 3) Whole map rotated 45 degrees

-- For best balance run the following commands after map generation:
-- /silent-command game.forces["player"].technologies["landfill"].enabled = false
-- /silent-command game.forces.player.character_running_speed_modifier = 1.5
-- /silent-command game.difficulty_settings.technology_price_multiplier=2

local b = require 'map_gen.shared.builders'
local Random = require 'map_gen.shared.random'
local math = require "utils.math"
local table = require 'utils.table'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

local degrees = math.rad

local ore_seed1 = 1000
local ore_seed2 = ore_seed1 * 2
local island_separation = 350

RS.set_map_gen_settings(
    {
        MGSP.ore_oil_none,
        MGSP.cliff_none
    }
)

local track = {
    b.translate(b.line_x(3), 0, -3),
    b.translate(b.line_x(3), 0, 3),
    b.translate(b.line_x(3), 0, -9),
    b.translate(b.line_x(3), 0, 9),
    b.rectangle(3, 22)
}

local h_track = b.any(track)
h_track = b.single_x_pattern(h_track, 15)
local v_track = b.rotate(h_track,degrees(90))

local square = b.rectangle(190, 190)
local circle = b.circle(80)

local leg = b.rectangle(32, 480)
local head = b.translate(b.oval(32, 64), 0, -64)
local body = b.translate(b.circle(64), 0, 64)

local count = 10
local angle = 360 / count
local list = {head, body}
for i = 1, (count / 2) - 1 do
    local shape = b.rotate(leg, degrees(i * angle))
    table.insert(list, shape)
end

local spider = b.any(list)
local ore_spider = b.scale(spider, 0.125, 0.125)

local function value(base, mult, pow)
    return function(x, y)
        local d_sq = x * x + y * y
        return base + mult * d_sq ^ ( pow / 2 ) -- d ^ pow
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
    return shape
end

local ores = {
    {transform = non_transform, resource = 'iron-ore', value = value(500, 0.75, 1.1), weight = 16},
    {transform = non_transform, resource = 'copper-ore', value = value(400, 0.75, 1.1), weight = 10},
    {transform = non_transform, resource = 'stone', value = value(250, 0.3, 1.05), weight = 3},
    {transform = non_transform, resource = 'coal', value = value(400, 0.8, 1.075), weight = 5},
    {transform = uranium_transform, resource = 'uranium-ore', value = value(200, 0.3, 1.025), weight = 3},
    {transform = oil_transform, resource = 'crude-oil', value = value(60000, 50, 1.025), weight = 6}
}

local total_ore_weights = {}
local ore_t = 0
for _, v in ipairs(ores) do
    ore_t = ore_t + v.weight
    table.insert(total_ore_weights, ore_t)
end

local random_ore = Random.new(ore_seed1, ore_seed2)
local pattern = {}

for r = 1, 50 do
    local row = {}
    pattern[r] = row
    local odd_r = (r % 2) == 1
    for c = 1, 50 do
        local odd_c = (c % 2) == 1

        if odd_r == odd_c then
            row[c] = square
        else
            local i = random_ore:next_int(1, ore_t)
            local index = table.binary_search(total_ore_weights, i)
            if (index < 0) then
                index = bit32.bnot(index)
            end
            local ore_data = ores[index]

            local ore_shape = ore_data.transform(ore_spider)
            local ore = b.resource(ore_shape, ore_data.resource, ore_data.value)

            local shape = circle
            shape = b.apply_entity(shape, ore)

            row[c] = shape
        end
    end
end

local start_patch = b.scale(spider, 0.0625, 0.0625)
local start_iron_patch =
    b.resource(
    b.translate(start_patch, 64, 0),
    'iron-ore',
    function()
        return 1500
    end
)
local start_copper_patch =
    b.resource(
    b.translate(start_patch, 0, -64),
    'copper-ore',
    function()
        return 1200
    end
)
local start_stone_patch =
    b.resource(
    b.translate(start_patch, -64, 0),
    'stone',
    function()
        return 600
    end
)
local start_coal_patch =
    b.resource(
    b.translate(start_patch, 0, 64),
    'coal',
    function()
        return 1350
    end
)

local start_resources = b.any({start_iron_patch, start_copper_patch, start_stone_patch, start_coal_patch})
local start = b.apply_entity(b.square_diamond(254), start_resources)

local map = b.grid_pattern(pattern, 50, 50, island_separation, island_separation)
map = b.choose(b.rectangle(350, 350), start, map)

local paths =
    b.any {
    b.single_y_pattern(h_track, island_separation),
    b.single_x_pattern(v_track, island_separation)
}

local sea = b.tile('deepwater')
sea = b.fish(sea, 0.0025)

map = b.any {map, paths, sea}

map = b.change_map_gen_collision_tile(map, 'water-tile', 'grass-1')
map = b.rotate(map,degrees(45))

return map
