local b = require 'map_gen.shared.builders'

local spiral = b.rectangular_spiral(1)

local factor = 9
local f = factor
local shape = b.single_spiral_rotate_pattern(spiral, f, f)
f = f * factor
shape = b.single_spiral_rotate_pattern(shape, f, f)

shape = b.scale(shape, 64)

return shape
