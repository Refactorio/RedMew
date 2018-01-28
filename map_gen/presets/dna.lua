--[[
This map uses custom ore gen. When generating the map, under the resource settings tab use Size = 'None' for all resources.
]]

map_gen_decoratives = false -- Generate our own decoratives
map_gen_rows_per_tick = 8 -- Inclusive integer between 1 and 32. Used for map_gen_threaded, higher numbers will generate map quicker but cause more lag.

-- Recommend to use generate, but generate_not_threaded may be useful for testing / debugging.
--require "map_gen.shared.generate_not_threaded"
require "map_gen.shared.generate"

local ball_r = 16
local big_circle = circle_builder(ball_r)
local small_circle = circle_builder(0.6 * ball_r)

local ribben = {big_circle}
local count = 8
local angle = math.pi / count
local offset_x = 32
local offset_y = 96
for i= 1, count do
    local x = offset_x * i
    local y = offset_y * math.sin(angle * i)
    local c = translate(big_circle, x, y)
    table.insert(ribben, c)
end
for i= 0, count - 1 do
    local j = i + 0.5
    local x = offset_x * j
    local y = offset_y * math.sin(angle * j)
    local c = translate(small_circle, x, y)
    table.insert(ribben, c)
end
ribben = compound_or(ribben)

local function value(mult,base)
    return function(a, b)
        return mult * (math.abs(a) + math.abs(b)) + base
    end
end

local oil_shape = circle_builder(0.16 * ball_r)
oil_shape = throttle_xy(oil_shape, 1, 2, 1, 2)

local resources =
{
    resource_module_builder(circle_builder(0.2 * ball_r), "iron-ore", value(0.5, 750)),
    resource_module_builder(circle_builder(0.2 * ball_r), "copper-ore", value(0.5, 750)),
    resource_module_builder(circle_builder(0.15 * ball_r), "stone", value(0.2, 400)),
    resource_module_builder(circle_builder(0.05 * ball_r), "uranium-ore", value(0.2, 600)),
    resource_module_builder(oil_shape, "crude-oil", value(60, 160000)),
    resource_module_builder(circle_builder(0.2 * ball_r), "coal", value(0.2, 600)),
    resource_module_builder(circle_builder(0.2 * ball_r), "iron-ore", value(0.5, 750))
}

local lines = {}
local lines_circle = circle_builder(0.6 * ball_r)
for i = 1, count - 1 do
    local x = offset_x * i
    local y = offset_y * math.sin(angle * i)

    local l = rectangle_builder(2, 2 * y + ball_r)
    l = translate(l, x, 0)
    
    local c = lines_circle
    c = builder_with_resource(c, resources[i])
    c = change_map_gen_collision_tile(c,"water-tile", "grass-1")
    local c = translate(c, x, 0)    

    table.insert(lines, c)
    table.insert(lines, l)
end
lines = compound_or(lines)

local dna = compound_or{lines, ribben, flip_y(ribben)}





local widith = offset_x * count
dna = translate(dna, -widith/ 2, 0)
local map = single_x_pattern_builder(dna, widith)
--[[ 
local dna1 = single_pattern_builder(dna, widith, 6 * widith)
local dna2 = single_pattern_builder(dna, widith, 8 * widith)
dna2 = rotate(dna2, degrees(60))
dna2 = translate(dna2, -3 * widith, 0)
local dna3 = single_pattern_builder(dna, widith, 8 * widith)
local dna3 = rotate(dna3, degrees(120))
dna3 = translate(dna3, 3 * widith, 0)
local map = compound_or{dna1, dna2, dna3}
 ]]

map = translate(map, -widith/2, 0)
map = rotate(map, degrees(45))

local start_circle =  circle_builder(0.3 * ball_r)

local iron = builder_with_resource(scale(start_circle,0.5,0.5), resource_module_builder(full_builder, "iron-ore", value(0, 700)))
local copper = builder_with_resource(scale(start_circle,0.5,0.5), resource_module_builder(full_builder, "copper-ore", value(0, 500)))
local stone = builder_with_resource(scale(start_circle,0.5,0.5), resource_module_builder(full_builder, "stone", value(0, 250)))
local oil = builder_with_resource(scale(start_circle,0.1,0.1), resource_module_builder(full_builder, "crude-oil", value(0, 40000)))
local coal = builder_with_resource(scale(start_circle,0.5,0.5), resource_module_builder(full_builder, "coal", value(0, 800)))

local start = compound_or
{
    translate(iron, 0, -9),
    translate(copper, 0, 9),
    translate(stone, -9, 0),
    translate(oil, 9, 9),
    translate(coal, 9, 0),
    
}
start = change_map_gen_collision_tile(start,"water-tile", "grass-1")
start = compound_or{start, big_circle}

map = choose(big_circle, start, map)

map = scale(map, 6, 6)
return map

