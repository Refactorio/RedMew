local b = require "map_gen.shared.builders"
local degrees = require "utils.math".degrees

local small_circle = b.circle(16)
local big_circle = b.circle(18)
local ring = b.all{big_circle, b.invert(small_circle)}

local box = b.rectangle(10,10)
box = b.translate(box, 16, -16)
local line = b.rectangle(36,1)
line = b.translate(line, 0, -20.5)
box = b.any{box, line}

local boxes = {}
for i = 0, 3 do
    local b = b.rotate(box, degrees(i*90)) -- luacheck: ignore 421
    table.insert(boxes, b)
end

boxes = b.any(boxes)

local shape = b.any{ring, boxes}

local shapes ={}
local sf = 1.8
local sf_total = 1
for i = 1, 10 do
    sf_total = sf_total * sf
    local s = b.scale(shape, sf_total, sf_total)
    table.insert(shapes, s)
end

local map = b.any(shapes)

return map
