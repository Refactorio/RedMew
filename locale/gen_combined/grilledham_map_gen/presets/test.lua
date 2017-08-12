require "locale.gen_combined.grilledham_map_gen.map_gen"
require "locale.gen_combined.grilledham_map_gen.builders"

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

map = change_map_gen_collision_tile(map, "water-tile", "grass")

return map