local b = require 'map_gen.shared.builders'

local spiral = b.circular_spiral_grow_n_threads(2, 4, 64, 8)
spiral = b.any {spiral, b.circle(4)}
spiral = b.choose(b.circle(16), spiral, b.empty_shape)

--local squares = b.single_x_pattern(spiral, 64)
local squares = b.single_pattern_overlap(spiral, 64, 64)
squares = b.linear_grow(squares, 64)

local function crop(x, y)
    return x > 0 and y > 0
end

crop = b.rotate(crop, degrees(-45))

--local quarter = b.choose(crop, squares, b.empty_shape)
local quarter = squares

local count = 4
local delta = tau / count
local angle = (3 / 8) * tau
local whole = {}
for i = 1, count do
    whole[i] = b.rotate(quarter, angle)
    angle = angle + delta
end

local ore_shape = b.segment_pattern(whole)
local ore_shape = b.circular_spiral_grow_n_threads(16, 128, 2048, 8)
ore_shape = b.flip_x(ore_shape)

local iron = b.apply_entity(b.full_shape, b.resource(ore_shape, 'iron-ore'))
local copper = b.apply_entity(b.full_shape, b.resource(ore_shape, 'copper-ore'))
local stone = b.apply_entity(b.full_shape, b.resource(ore_shape, 'stone'))
local coal = b.apply_entity(b.full_shape, b.resource(ore_shape, 'coal'))
local uranium = b.apply_entity(b.full_shape, b.resource(ore_shape, 'uranium-ore'))
local oil = b.apply_entity(b.full_shape, b.resource(ore_shape, 'crude-oil'))

local void_spiral = b.circular_spiral_grow_n_threads(8, 32, 512, 8)
void_spiral = b.rotate(void_spiral, degrees(-39))
local void_circle = b.circle(256)
local void = b.choose(void_circle, void_spiral, b.empty_shape)

local walk_spiral = b.circular_spiral_n_threads(5, 512, 8)
walk_spiral = b.flip_x(walk_spiral)

local map =
    b.circular_spiral_grow_pattern(16, 32, 512, {b.full_shape, iron, stone, coal, b.full_shape, copper, uranium, oil})

--map = b.subtract(map, void)
map = b.any {b.circle(64), map, walk_spiral}

--local map = b.apply_entity(main_spiral, ore)

return map
