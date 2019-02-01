local b = require 'map_gen.shared.builders'
local math = require 'utils.math'
local degrees = math.degrees
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

RS.set_map_gen_settings(
    {
        MGSP.ore_oil_none,
        MGSP.cliff_none
    }
)

local ball_r = 16
local big_circle = b.circle(ball_r)
local small_circle = b.circle(0.6 * ball_r)

local ribben = {big_circle}
local count = 8
local angle = math.pi / count
local offset_x = 32
local offset_y = 96
for i = 1, count do
    local x = offset_x * i
    local y = offset_y * math.sin(angle * i)
    local c = b.translate(big_circle, x, y)
    table.insert(ribben, c)
end
for i = 0, count - 1 do
    local j = i + 0.5
    local x = offset_x * j
    local y = offset_y * math.sin(angle * j)
    local c = b.translate(small_circle, x, y)
    table.insert(ribben, c)
end
ribben = b.any(ribben)

local value = b.manhattan_value
local inf = function()
    return 100000000
end

local oil_shape = b.circle(0.16 * ball_r)
oil_shape = b.throttle_world_xy(oil_shape, 1, 4, 1, 4)

local resources = {
    b.any {
        b.resource(b.circle(0.02 * ball_r), 'iron-ore', inf),
        b.resource(b.circle(0.2 * ball_r), 'iron-ore', value(750, 0.5))
    },
    b.any {
        b.resource(b.circle(0.02 * ball_r), 'copper-ore', inf),
        b.resource(b.circle(0.2 * ball_r), 'copper-ore', value(750, 0.5))
    },
    b.any {
        b.resource(b.circle(0.015 * ball_r), 'stone', inf),
        b.resource(b.circle(0.15 * ball_r), 'stone', value(400, 0.2))
    },
    b.any {
        b.resource(b.circle(0.005 * ball_r), 'uranium-ore', inf),
        b.resource(b.circle(0.05 * ball_r), 'uranium-ore', value(600, 0.2))
    },
    b.resource(oil_shape, 'crude-oil', value(120000, 50)),
    b.any {
        b.resource(b.circle(0.02 * ball_r), 'coal', inf),
        b.resource(b.circle(0.2 * ball_r), 'coal', value(600, 0.2))
    },
    b.any {
        b.resource(b.circle(0.02 * ball_r), 'iron-ore', inf),
        b.resource(b.circle(0.2 * ball_r), 'iron-ore', value(750, 0.5))
    }
}

local lines = {}
local lines_circle = b.circle(0.6 * ball_r)
for i = 1, count - 1 do
    local x = offset_x * i
    local y = offset_y * math.sin(angle * i)

    local l = b.rectangle(2, 2 * y + ball_r)
    l = b.translate(l, x, 0)

    local c = lines_circle
    c = b.apply_entity(c, resources[i])
    c = b.change_map_gen_collision_tile(c, 'water-tile', 'grass-1')
    c = b.translate(c, x, 0)

    table.insert(lines, c)
    table.insert(lines, l)
end
lines = b.any(lines)

local dna = b.any {lines, ribben, b.flip_y(ribben)}

local widith = offset_x * count
dna = b.translate(dna, -widith / 2, 0)
local map = b.single_x_pattern(dna, widith)

map = b.translate(map, -widith / 2, 0)

local sea = b.sine_fill(512, 208)
sea = b.any {b.line_x(2), sea, b.flip_y(sea)}
sea = b.change_tile(sea, true, 'water')
sea = b.fish(sea, 0.0025)

map = b.any {map, sea}

map = b.rotate(map, degrees(45))

local start_circle = b.circle(0.3 * ball_r)

local start_iron =
    b.any {
    b.resource(b.rectangle(0.2), 'iron-ore', inf),
    b.resource(b.full_shape, 'iron-ore', value(700, 0))
}
local start_copper =
    b.any {
    b.resource(b.rectangle(0.2), 'copper-ore', inf),
    b.resource(b.full_shape, 'copper-ore', value(500, 0))
}
local start_stone =
    b.any {
    b.resource(b.rectangle(0.2), 'stone', inf),
    b.resource(b.full_shape, 'stone', value(250, 0))
}
local start_coal =
    b.any {
    b.resource(b.rectangle(0.2), 'coal', inf),
    b.resource(b.full_shape, 'coal', value(800, 0))
}

local iron = b.apply_entity(b.scale(start_circle, 0.5, 0.5), start_iron)
local copper = b.apply_entity(b.scale(start_circle, 0.5, 0.5), start_copper)
local stone = b.apply_entity(b.scale(start_circle, 0.5, 0.5), start_stone)
local oil = b.apply_entity(b.scale(start_circle, 0.1, 0.1), b.resource(b.full_shape, 'crude-oil', value(40000, 0)))
local coal = b.apply_entity(b.scale(start_circle, 0.5, 0.5), start_coal)

local start =
    b.any {
    b.translate(iron, 0, -9),
    b.translate(copper, 0, 9),
    b.translate(stone, -9, 0),
    b.translate(oil, 9, 9),
    b.translate(coal, 9, 0)
}

start = b.any {start, big_circle}

map = b.choose(big_circle, start, map)
map = b.change_map_gen_collision_tile(map, 'water-tile', 'grass-1')

map = b.scale(map, 5, 5)

return map
