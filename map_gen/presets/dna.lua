--[[
This map uses custom ore gen. When generating the map, under the resource settings tab use Size = 'None' for all resources.
]]

map_gen_decoratives = false -- Generate our own decoratives
map_gen_rows_per_tick = 8 -- Inclusive integer between 1 and 32. Used for map_gen_threaded, higher numbers will generate map quicker but cause more lag.

-- Recommend to use generate, but generate_not_threaded may be useful for testing / debugging.
--require "map_gen.shared.generate_not_threaded"
require "map_gen.shared.generate"

local b = require "map_gen.shared.builders"

local ball_r = 16
local big_circle = b.circle(ball_r)
local small_circle = b.circle(0.6 * ball_r)

local ribben = {big_circle}
local count = 8
local angle = math.pi / count
local offset_x = 32
local offset_y = 96
for i= 1, count do
    local x = offset_x * i
    local y = offset_y * math.sin(angle * i)
    local c = b.translate(big_circle, x, y)
    table.insert(ribben, c)
end
for i= 0, count - 1 do
    local j = i + 0.5
    local x = offset_x * j
    local y = offset_y * math.sin(angle * j)
    local c = b.translate(small_circle, x, y)
    table.insert(ribben, c)
end
ribben = b.any(ribben)

local function value(mult,base)
    return function(a, b)
        return mult * (math.abs(a) + math.abs(b)) + base
    end
end

local oil_shape = b.circle(0.16 * ball_r)
oil_shape = b.throttle_world_xy(oil_shape, 1, 4, 1, 4)

local resources =
{
    b.resource(b.circle(0.2 * ball_r), "iron-ore", value(0.5, 750)),
    b.resource(b.circle(0.2 * ball_r), "copper-ore", value(0.5, 750)),
    b.resource(b.circle(0.15 * ball_r), "stone", value(0.2, 400)),
    b.resource(b.circle(0.05 * ball_r), "uranium-ore", value(0.2, 600)),
    b.resource(oil_shape, "crude-oil", value(60, 160000)),
    b.resource(b.circle(0.2 * ball_r), "coal", value(0.2, 600)),
    b.resource(b.circle(0.2 * ball_r), "iron-ore", value(0.5, 750))
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
    c = b.change_map_gen_collision_tile(c,"water-tile", "grass-1")
    local c = b.translate(c, x, 0)    

    table.insert(lines, c)
    table.insert(lines, l)
end
lines = b.any(lines)

local dna = b.any{lines, ribben, b.flip_y(ribben)}

local widith = offset_x * count
dna = b.translate(dna, -widith/ 2, 0)
local map = b.single_x_pattern(dna, widith)
--[[ 
local dna1 = b.single_pattern(dna, widith, 6 * widith)
local dna2 = b.single_pattern(dna, widith, 8 * widith)
dna2 = b.rotate(dna2, degrees(60))
dna2 = b.translate(dna2, -3 * widith, 0)
local dna3 = b.single_pattern(dna, widith, 8 * widith)
local dna3 = b.rotate(dna3, degrees(120))
dna3 = b.translate(dna3, 3 * widith, 0)
local map = b.any{dna1, dna2, dna3}
 ]]

map = b.translate(map, -widith/2, 0)

local sea = b.sine_fill(512, 208)
sea = b.any{b.line_x(2), sea, b.flip_y(sea)}
sea = b.change_tile(sea, true, "water")
sea = b.fish(sea, 0.005)

map = b.any{map, sea}

map = b.rotate(map, degrees(45))

local start_circle =  b.circle(0.3 * ball_r)

local iron = b.apply_entity(b.scale(start_circle,0.5,0.5), b.resource(b.full_shape, "iron-ore", value(0, 700)))
local copper = b.apply_entity(b.scale(start_circle,0.5,0.5), b.resource(b.full_shape, "copper-ore", value(0, 500)))
local stone = b.apply_entity(b.scale(start_circle,0.5,0.5), b.resource(b.full_shape, "stone", value(0, 250)))
local oil = b.apply_entity(b.scale(start_circle,0.1,0.1), b.resource(b.full_shape, "crude-oil", value(0, 40000)))
local coal = b.apply_entity(b.scale(start_circle,0.5,0.5), b.resource(b.full_shape, "coal", value(0, 800)))

local start = b.any
{
    b.translate(iron, 0, -9),
    b.translate(copper, 0, 9),
    b.translate(stone, -9, 0),
    b.translate(oil, 9, 9),
    b.translate(coal, 9, 0),
    
}
--start = b.change_map_gen_collision_tile(start,"water-tile", "grass-1")
start = b.any{start, big_circle}

map = b.choose(big_circle, start, map)
map = b.change_map_gen_collision_tile(map, "water-tile", "grass-1")

map = b.scale(map, 6, 6)

return map

