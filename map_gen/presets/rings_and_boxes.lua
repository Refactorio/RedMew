map_gen_decoratives = false -- Generate our own decoratives
map_gen_rows_per_tick = 8 -- Inclusive integer between 1 and 32. Used for map_gen_threaded, higher numbers will generate map quicker but cause more lag.

-- Recommend to use generate, but generate_not_threaded may be useful for testing / debugging.
--require "map_gen.shared.generate_not_threaded"
require "map_gen.shared.generate"

local small_circle = circle_builder(16)
local big_circle = circle_builder(18)
local ring = compound_and{big_circle, invert(small_circle)}

local box = rectangle_builder(10,10)
box = translate(box, 16, -16)
local line = rectangle_builder(36,1)
line = translate(line, 0, -20.5)
box = compound_or{box, line}

local boxes = {}
for i = 0, 3 do
    local b = rotate(box, degrees(i*90))
    table.insert(boxes, b)
end

boxes = compound_or(boxes)

local shape = compound_or{ring, boxes}

local shapes ={}
local sf = 1.8
local sf_total = 1
for i = 1, 10 do
    sf_total = sf_total * sf
    local s = scale(shape, sf_total, sf_total)
    table.insert(shapes, s)
end

local map = compound_or(shapes)

return map