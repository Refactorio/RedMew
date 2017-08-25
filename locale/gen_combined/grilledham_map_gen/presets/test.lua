require "locale.gen_combined.grilledham_map_gen.map_gen"
require "locale.gen_combined.grilledham_map_gen.builders"

--[[
local square = rectangle_builder(32,32)
local circle = circle_builder(16)
local path = path_builder(8)
path = change_tile(path, true, "water")

square = compound_or({square, path})
circle = compound_or({circle, path})

local pattern = 
{
    {square, circle},
    {circle, square}
}

local map = grid_pattern_builder(pattern, 2, 2, 64, 64)
map = rotate(map, degrees(45))

local start = rectangle_builder(48,48)

map = choose(start, start, map)

map = scale(map, 4, 4)

map = change_map_gen_collision_tile(map, "water-tile", "grass")

return map

--]]


--local shape = circle_builder(9)
--local shape = oval_builder(9, 10)
--local shape = rectangle_builder(10, 10)
local pic = require "locale.gen_combined.grilledham_map_gen.data.goat"
local shape = picture_builder(pic.data, pic.width, pic.height)
--local shape = path_builder(2,4)
--local shape = square_diamond_builder(7)
--local shape = rotate(rectangle_builder(8,8), degrees(45))

local shape = require "locale.gen_combined.grilledham_map_gen.presets.mobius_strip"

--local shape = path_builder(4)
--shape = compound_or({ shape, rotate(shape, degrees(45)) })


--shape = single_pattern_builder(shape,64,64)
--shape = project(shape, pic.height / 2 , 1.25)
shape = project_overlap(shape, 128, 1.1875)

local crop = translate(rectangle_builder(1000000,1000000), 0, -500000 - pic.height / 2)
crop = invert(crop)
shape = compound_and({ crop, shape })


--shape = scale(shape, 0.125, 0.125)
--shape = rotate(shape, degrees(45))

shape = compound_or(
    { 
        shape,
        rotate(shape, degrees(45)),
        rotate(shape, degrees(90)), 
        rotate(shape, degrees(135)), 
        rotate(shape, degrees(180)), 
        rotate(shape, degrees(225)), 
        rotate(shape, degrees(270)),
        rotate(shape, degrees(315)),        
    })

shape = scale(shape, 0.125, 0.125)

return shape