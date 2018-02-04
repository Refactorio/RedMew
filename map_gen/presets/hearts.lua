-- Recommend to use generate, but generate_not_threaded may be useful for testing / debugging.
--require "map_gen.shared.generate_not_threaded"
require "map_gen.shared.generate"

local circle = circle_builder(16)
local square = rectangle_builder(30)
square = rotate(square, degrees(45))

local heart = compound_or{translate(circle, -14, 0), translate(circle, 14, 0), translate(square, 0, 14)}
--local hollow_heart = compound_and{invert(heart), scale(heart, 2, 2)}

heart = translate(heart, 0, -10)
heart = scale(heart, 51/60, 1)
local hearts = grow(heart, heart, 52, 0.5)

local line = line_y_builder(2)

local map = compound_or{line, hearts}
map = translate(map, 0, 16)
map = scale(map, 12,12)

return map