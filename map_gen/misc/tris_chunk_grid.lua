local b = require 'map_gen.shared.builders'

local size = 8 * 32

local concrete = b.tile('concrete')
local hazard = b.change_tile(b.rectangle(size - 4, size - 4), true, 'hazard-concrete-left')
local stone = b.change_tile(b.rectangle(size - 6, size - 6), true, 'stone-path')
local empty = b.rectangle(size - 8, size - 8)

local shape = b.any {stone, hazard, concrete}
shape = b.subtract(shape, empty)

shape = b.single_pattern(shape, size, size)

return shape
