map_gen_decoratives = false -- Generate our own decoratives
map_gen_rows_per_tick = 8 -- Inclusive integer between 1 and 32. Used for map_gen_threaded, higher numbers will generate map quicker but cause more lag.

-- Recommend to use generate, but generate_not_threaded may be useful for testing / debugging.
--require "map_gen.shared.generate_not_threaded"
require "map_gen.shared.generate"

local ball = circle_builder(16)

local arm = rectangle_builder(2, 13)
local arm1 = translate(arm, 0, -19.5)
local arm2 = translate(arm, 0, 22)
local arm3 = rectangle_builder(2, 19)
arm3 = rotate(arm3, degrees(-30))
arm3 = translate(arm3, -12, 22)

ball = compound_or{ball, arm1, arm2, arm3}
ball = translate(ball, 0, -28)

local balls = compound_or{ball, rotate(ball, degrees(120)), rotate(ball, degrees(240))}

local small_circle = circle_builder(48)
local big_circle = circle_builder(54)
local ring = compound_and{big_circle, invert(small_circle)}

local big_ball = compound_or{balls, ring}

local big_arm1 = rectangle_builder(6.75, 42.5)
big_arm1 = translate(big_arm1, 0, -74.25)
--local big_arm2 = rectangle_builder(24, 242)
--big_arm2 = translate(big_arm2, 0, 174)

big_ball = compound_or{big_ball, big_arm1, big_arm2}

big_ball = rotate(big_ball, degrees(-90))
big_ball = rotate(big_ball, math.atan2(54,210))
big_ball = translate(big_ball, 210, -54)

local big_balls = {}
local count = 12
local angle = 360 / count
local offset = (180 / count) + 90
for i = 0, count - 1 do
    local s =rotate(big_ball, degrees(i * angle ))
    table.insert(big_balls, s)
end

local big_balls = segment_pattern_builder(big_balls)


local small_circle = circle_builder(304.5)
local big_circle = circle_builder(316.5) --342.5625
local ring = compound_and{big_circle, invert(small_circle)}

local map = compound_or{big_balls, ring}

local leg = rectangle_builder(32,480)
local head = translate (oval_builder(32, 64), 0, -64)
local body = translate (circle_builder(64), 0, 64)

local count = 10
local angle = 360 / count
local list = { head, body }
for i = 1, (count / 2) - 1 do
    local shape = rotate(leg, degrees(i * angle))
    table.insert( list, shape )
end  

local spider = compound_or(list) 
spider = scale(spider,.75,.75)

--map = compound_or{map, spider}
map = translate(map, -30, 201)
map = scale(map, 12, 12)

return map