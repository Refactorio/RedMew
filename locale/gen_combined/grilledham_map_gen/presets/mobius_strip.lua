require "locale.gen_combined.grilledham_map_gen.map_gen"
require "locale.gen_combined.grilledham_map_gen.builders"

local inner_circle = invert(circle_builder(48))
local outer_circle = circle_builder(64)
local square = invert(rectangle_builder(68,68))
square = rotate(square, degrees(45))
square = translate(square, 56,0)

local circle = compound_and({ inner_circle, outer_circle, square })

local line1 = rectangle_builder(66,16)
line1 = rotate(line1, degrees(45))
line1 = translate(line1,66.5,12.25)

local line2 = rectangle_builder(46, 16)
local line2 = rotate(line2, degrees(-45))
line2 = translate(line2, 55.5,-23.5)

--line2 =change_tile(line2, true, "water")

local half = compound_or({ line2,line1,circle})

half = translate(half, -78.625, 0)
local map = compound_or({ half, flip_xy(half) })

map = scale(map, 16, 16)

return map
