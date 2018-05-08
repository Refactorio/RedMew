--[[
This map uses custom ore gen. When generating the map, under the resource settings tab use Size = 'None' for all resources.
]]

local b = require "map_gen.shared.builders"

local square = b.rectangle(160,160)
local circle = b.circle(60)  

local leg = b.rectangle(32,480)
local head = b.translate (b.oval(32, 64), 0, -64)
local body = b.translate (b.circle(64), 0, 64)

local count = 10
local angle = 360 / count
local list = { head, body }
for i = 1, (count / 2) - 1 do
    local shape = b.rotate(leg, degrees(i * angle))
    table.insert( list, shape )
end  

local spider = b.any(list)   

local patch = b.scale(spider, 0.125, 0.125)
local iron_patch = b.resource(patch, "iron-ore", function(x,y) return 500 + (math.abs(x) + math.abs(y)) end)
local copper_patch = b.resource(patch, "copper-ore",function(x,y) return 400 + (math.abs(x) + math.abs(y)) * 0.8  end)
local coal_patch = b.resource(patch, "coal",function(x,y) return 300 + (math.abs(x) + math.abs(y)) * 0.7  end)
local stone_patch = b.resource(patch, "stone",function(x,y) return 100 + (math.abs(x) + math.abs(y)) * 0.5 end)
local uraniumn_patch = b.resource(b.scale(patch, 0.5,0.5), "uranium-ore",function(x,y) return 100 + (math.abs(x) + math.abs(y)) * 0.2 end)   
local oil_patch = b.resource(patch, "crude-oil",function(x,y) return 75000 + (math.abs(x) + math.abs(y)) * 500 end)

local iron_circle = b.apply_entity(circle, iron_patch)
local copper_circle = b.apply_entity(circle, copper_patch)
local coal_circle = b.apply_entity(circle, coal_patch)
local stone_circle = b.apply_entity(circle, stone_patch)
local uraniumn_circle = b.apply_entity(circle, uraniumn_patch)
local oil_circle = b.apply_entity(circle, oil_patch)

local start_patch = b.scale(spider, 0.0625, 0.0625)
local start_iron_patch = b.resource(b.translate(start_patch, 48, 0), "iron-ore", function(x,y) return 500 end)
local start_copper_patch = b.resource(b.translate(start_patch, 0, -48), "copper-ore", function(x,y) return 400 end)
local start_stone_patch = b.resource(b.translate(start_patch, -48, 0), "stone", function(x,y) return 200 end)
local start_coal_patch = b.resource(b.translate(start_patch, 0, 48), "coal", function(x,y) return 300 end)

local start_resources = b.any({ start_iron_patch, start_copper_patch, start_stone_patch, start_coal_patch })
local start = b.apply_entity(b.square_diamond(224), start_resources)

pattern =
{
    { square, iron_circle, square, iron_circle, square, stone_circle },
    { coal_circle, square, oil_circle, square, copper_circle, square },
    { square, iron_circle, square, copper_circle, square, coal_circle },
    { stone_circle, square, uraniumn_circle, square, iron_circle, square },
    { square, iron_circle, square, oil_circle, square, copper_circle },
    { copper_circle, square, iron_circle, square, coal_circle, square },
}

local map = b.grid_pattern(pattern, 6, 6, 288, 288)
map = b.choose(b.rectangle(288,288), start, map)

local path = b.path(16)
local paths = b.single_pattern(path, 288, 288)

map = b.any{map, paths}

return map