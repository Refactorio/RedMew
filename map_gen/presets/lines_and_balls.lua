map_gen_decoratives = false -- Generate our own decoratives
map_gen_rows_per_tick = 8 -- Inclusive integer between 1 and 32. Used for map_gen_threaded, higher numbers will generate map quicker but cause more lag.

-- Recommend to use generate, but generate_not_threaded may be useful for testing / debugging.
--require "map_gen.shared.generate_not_threaded"
require "map_gen.shared.generate"

local b = require "map_gen.shared.builders"

local big_circle = b.circle(150)
local small_circle = b.circle(140)
local crop = b.rectangle(300,150)
crop = b.translate(crop,0,-75)
local arc = b.all{big_circle, b.invert(small_circle), b.invert(crop)}
arc = b.scale(arc,12,4)

local circle = b.circle(200)
local ball1 = b.translate(circle, 0,820)
local ball2 = b.translate(circle, -920,740)
local ball3 = b.translate(circle, 920,740)
local rectangle = b.rectangle(25,40)
local arm1 = b.translate(rectangle, 0, 610)
local arm2 = b.translate(rectangle, -920, 530)
local arm3 = b.translate(rectangle, 920, 530)

local arc1 = b.any{arc, ball1,ball2,ball3,arm1,arm2,arm3}
arc1 = b.single_pattern(arc1, 2760,2760)

local root2 = math.sqrt(2)
circle = b.circle(200 / root2)
ball1 = b.translate(circle, -0,770)
ball2 = b.translate(circle, -920,690)
ball3 = b.translate(circle, 920,690)
rectangle = b.rectangle(25,40)
arm1 = b.translate(rectangle, 0, 610)
arm2 = b.translate(rectangle, -920, 530)
arm3 = b.translate(rectangle, 920, 530)

local arc2 = b.any{arc, ball1,ball2,ball3,arm1,arm2,arm3}
arc2 = b.single_pattern(arc2, 2760,2760)

local arc2 = b.rotate(arc2,degrees(45))
arc2 = b.scale(arc2, root2,root2)
arc2 = b.translate(arc2, -330,-1375)

local map = b.any{arc1,arc2}
map = b.translate(map,0,-700)
--map = b.scale(map, .2, .2)

return map