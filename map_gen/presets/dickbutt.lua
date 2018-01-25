--[[
This map uses custom ore gen. When generating the map, under the resource settings tab use Size = 'None' for iron, copper, stone and coal.
]]

map_gen_decoratives = false -- Generate our own decoratives
map_gen_rows_per_tick = 8 -- Inclusive integer between 1 and 32. Used for map_gen_threaded, higher numbers will generate map quicker but cause more lag.

-- Recommend to use generate, but generate_not_threaded may be useful for testing / debugging.
--require "map_gen.shared.generate_not_threaded"
require "map_gen.shared.generate"

local body = rotate(oval_builder(128,256), degrees(20))
local butt = translate(rotate(oval_builder(180, 128), degrees(30)), 130,100)

local shaft = translate(rotate(oval_builder(32, 80), degrees(0)), 220, -80)
local ball1 = translate(rotate(oval_builder(32,16), degrees(10)), 250,-50)
local ball2 = translate(rotate(oval_builder(48,16), degrees(5)), 240,-40)

local leg1 = translate(rotate(rectangle_builder(16, 80), degrees(175)), 80, 280)
local leg2 = translate(rotate(rectangle_builder(16, 80), degrees(5)), 180, 250)
local foot1 = translate(rotate(rectangle_builder(16, 40), degrees(65)), 65, 315)
local foot2 = translate(rotate(rectangle_builder(16, 40), degrees(65)), 170, 285)

local eye1 = translate(circle_builder(32),-130, -100)   

local dickbutt = compound_or({body,butt,  shaft, ball1, ball2, leg1, leg2, foot1, foot2, eye1 })
dickbutt = translate(dickbutt, -80, 0)

local patch = scale(dickbutt, 0.15, 0.15)
local iron_patch = resource_module_builder(translate(scale(dickbutt, 0.15, 0.15), 20, 0), "iron-ore")
local copper_patch = resource_module_builder(translate(scale(dickbutt, 0.115, 0.115), -125, 50), "copper-ore")
local coal_patch = resource_module_builder(translate(scale(dickbutt, 0.1, 0.1), -135, -90), "coal")
local stone_patch = resource_module_builder(translate(scale(dickbutt, 0.075, 0.075), 50, 150), "stone")

local patches = compound_or({ iron_patch, copper_patch, coal_patch, stone_patch })

dickbutt = builder_with_resource(dickbutt, patches)

local dickbutt2 = rotate(dickbutt, degrees(45))
local dickbutt3 = rotate(dickbutt, degrees(90))
local dickbutt4 = rotate(dickbutt, degrees(135))
local dickbutt5 = rotate(dickbutt, degrees(180))

local pattern = 
{
    { dickbutt, dickbutt2, dickbutt3, dickbutt4, dickbutt5 },
    { dickbutt2, dickbutt3, dickbutt4, dickbutt5, dickbutt },
    { dickbutt3, dickbutt4, dickbutt5, dickbutt, dickbutt2 },
    { dickbutt4, dickbutt5, dickbutt, dickbutt2, dickbutt3 },
    { dickbutt5, dickbutt, dickbutt2, dickbutt3, dickbutt4 },
}

local map = grid_pattern_builder(pattern, 5, 5, 650, 650)
map = change_tile(map, false, "water")

return map