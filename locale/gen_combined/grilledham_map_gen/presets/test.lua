require "locale.gen_combined.grilledham_map_gen.map_gen"
require "locale.gen_combined.grilledham_map_gen.builders"

local square = rectangle_builder(32,32)
local circle = circle_builder(16)
local path = path_builder(8)

square = compound_or({square, path})
circle = compound_or({circle, path})

local pattern = 
{
    {square, circle},
    {circle, square}
}

local map = grid_pattern_builder(pattern, 2, 2, 64, 64)
--map = scale(map, 1, 1)
map = rotate(map, degrees(45))


map = single_pattern_builder(map, 128,128)
map = rotate(map, degrees(-45))

map = single_pattern_builder(map, 256, 256)
map = rotate(map, degrees(45))

return map