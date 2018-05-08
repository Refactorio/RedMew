--[[
This map uses custom ore gen. When generating the map, under the resource settings tab use Size = 'None' for iron, copper, stone and coal.
]]

map_gen_decoratives = false -- Generate our own decoratives
map_gen_rows_per_tick = 8 -- Inclusive integer between 1 and 32. Used for map_gen_threaded, higher numbers will generate map quicker but cause more lag.

-- Recommend to use generate, but generate_not_threaded may be useful for testing / debugging.
--require "map_gen.shared.generate_not_threaded"
require "map_gen.shared.generate"

local b = require "map_gen.shared.builders"

local body = b.rotate(b.oval(128,256), degrees(20))
local butt = b.translate(b.rotate(b.oval(180, 128), degrees(30)), 130,100)

local shaft = b.translate(b.rotate(b.oval(32, 80), degrees(0)), 220, -80)
local ball1 = b.translate(b.rotate(b.oval(32,16), degrees(10)), 250,-50)
local ball2 = b.translate(b.rotate(b.oval(48,16), degrees(5)), 240,-40)

local leg1 = b.translate(b.rotate(b.rectangle(16, 80), degrees(175)), 80, 280)
local leg2 = b.translate(b.rotate(b.rectangle(16, 80), degrees(5)), 180, 250)
local foot1 = b.translate(b.rotate(b.rectangle(16, 40), degrees(65)), 65, 315)
local foot2 = b.translate(b.rotate(b.rectangle(16, 40), degrees(65)), 170, 285)

local eye1 = b.translate(b.circle(32),-130, -100)   

local dickbutt = b.any({body,butt,  shaft, ball1, ball2, leg1, leg2, foot1, foot2, eye1 })
dickbutt = b.translate(dickbutt, -80, 0)

local patch = b.scale(dickbutt, 0.15, 0.15)
local iron_patch = b.resource(b.translate(b.scale(dickbutt, 0.15, 0.15), 20, 0), "iron-ore")
local copper_patch = b.resource(b.translate(b.scale(dickbutt, 0.115, 0.115), -125, 50), "copper-ore")
local coal_patch = b.resource(b.translate(b.scale(dickbutt, 0.1, 0.1), -135, -90), "coal")
local stone_patch = b.resource(b.translate(b.scale(dickbutt, 0.075, 0.075), 50, 150), "stone")

local patches = b.any({ iron_patch, copper_patch, coal_patch, stone_patch })

dickbutt = b.apply_entity(dickbutt, patches)

local dickbutt2 = b.rotate(dickbutt, degrees(45))
local dickbutt3 = b.rotate(dickbutt, degrees(90))
local dickbutt4 = b.rotate(dickbutt, degrees(135))
local dickbutt5 = b.rotate(dickbutt, degrees(180))

local pattern = 
{
    { dickbutt, dickbutt2, dickbutt3, dickbutt4, dickbutt5 },
    { dickbutt2, dickbutt3, dickbutt4, dickbutt5, dickbutt },
    { dickbutt3, dickbutt4, dickbutt5, dickbutt, dickbutt2 },
    { dickbutt4, dickbutt5, dickbutt, dickbutt2, dickbutt3 },
    { dickbutt5, dickbutt, dickbutt2, dickbutt3, dickbutt4 },
}

local map = b.grid_pattern(pattern, 5, 5, 650, 650)
map = b.change_tile(map, false, "water")

return map