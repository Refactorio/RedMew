local b = require "map_gen.shared.builders"
local degrees = require "utils.math".degrees

local circle = b.circle(16)
local square = b.rectangle(30)
square = b.rotate(square, degrees(45))

local heart = b.any{b.translate(circle, -14, 0), b.translate(circle, 14, 0), b.translate(square, 0, 14)}
--local hollow_heart = b.all{b.invert(heart), b.scale(heart, 2, 2)}

heart = b.translate(heart, 0, -10)
heart = b.scale(heart, 51/60, 1)
local hearts = b.grow(heart, heart, 52, 0.5)

local line = b.line_y(2)

local map = b.any{line, hearts}
map = b.translate(map, 0, 16)
map = b.scale(map, 12,12)

return map
