local b = require 'map_gen.shared.builders'

local spiral = b.rectangular_spiral(1)

local factor = 9
local shape = b.single_spiral_rotate_pattern(spiral, factor, factor)
factor = factor * factor
shape = b.single_spiral_rotate_pattern(shape, factor, factor)

shape = b.scale(shape, 64)

return shape
