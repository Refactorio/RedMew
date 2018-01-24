--[[
This map uses custom ore gen. When generating the map, under the resource settings tab use Size = 'None' for all resources.
]]

map_gen_decoratives = false -- Generate our own decoratives
map_gen_rows_per_tick = 8 -- Inclusive integer between 1 and 32. Used for map_gen_threaded, higher numbers will generate map quicker but cause more lag.

-- Recommend to use generate, but generate_not_threaded may be useful for testing / debugging.
--require "map_gen.shared.generate_not_threaded"
require "map_gen.shared.generate"

local square = rectangle_builder(160,160)
local circle = circle_builder(60)  

local leg = rectangle_builder(32,480)
local head = translate (oval_builder(32, 64), 0, -64)
local body = translate (circle_builder(64), 0, 64)

local count = 10
local angle = 360 / count
local list = { head, body }
for i = 1, (count / 2) - 1 do
    local shape = rotate(leg, degrees(i * angle))
    table.insert( list, shape )
end  

local spider = compound_or(list)   

local patch = scale(spider, 0.125, 0.125)
local iron_patch = resource_module_builder(patch, "iron-ore", function(x,y) return 500 + (math.abs(x) + math.abs(y)) end)
local copper_patch = resource_module_builder(patch, "copper-ore",function(x,y) return 400 + (math.abs(x) + math.abs(y)) * 0.8  end)
local coal_patch = resource_module_builder(patch, "coal",function(x,y) return 300 + (math.abs(x) + math.abs(y)) * 0.7  end)
local stone_patch = resource_module_builder(patch, "stone",function(x,y) return 100 + (math.abs(x) + math.abs(y)) * 0.5 end)
local uraniumn_patch = resource_module_builder(scale(patch, 0.5,0.5), "uranium-ore",function(x,y) return 100 + (math.abs(x) + math.abs(y)) * 0.2 end)   
local oil_patch = resource_module_builder(patch, "crude-oil",function(x,y) return 75000 + (math.abs(x) + math.abs(y)) * 500 end)

local iron_circle = builder_with_resource(circle, iron_patch)
local copper_circle = builder_with_resource(circle, copper_patch)
local coal_circle = builder_with_resource(circle, coal_patch)
local stone_circle = builder_with_resource(circle, stone_patch)
local uraniumn_circle = builder_with_resource(circle, uraniumn_patch)
local oil_circle = builder_with_resource(circle, oil_patch)

local start_patch = scale(spider, 0.0625, 0.0625)
local start_iron_patch = resource_module_builder(translate(start_patch, 48, 0), "iron-ore", function(x,y) return 500 end)
local start_copper_patch = resource_module_builder(translate(start_patch, 0, -48), "copper-ore", function(x,y) return 400 end)
local start_stone_patch = resource_module_builder(translate(start_patch, -48, 0), "stone", function(x,y) return 200 end)
local start_coal_patch = resource_module_builder(translate(start_patch, 0, 48), "coal", function(x,y) return 300 end)

local start_resources = compound_or({ start_iron_patch, start_copper_patch, start_stone_patch, start_coal_patch })
local start = builder_with_resource(square_diamond_builder(224), start_resources)

pattern =
{
    { square, iron_circle, square, iron_circle, square, stone_circle },
    { coal_circle, square, oil_circle, square, copper_circle, square },
    { square, iron_circle, square, copper_circle, square, coal_circle },
    { stone_circle, square, uraniumn_circle, square, iron_circle, square },
    { square, iron_circle, square, oil_circle, square, copper_circle },
    { copper_circle, square, iron_circle, square, coal_circle, square },
}

local map = grid_pattern_builder(pattern, 6, 6, 288, 288)
map = choose(rectangle_builder(288,288), start, map)

local path = path_builder(16)
local paths = single_pattern_builder(path, 288, 288)

map = compound_or{map, paths}

return map