-- luacheck: ignore
-- please remove luacheck ignore when map is complete/functional
local b = require "map_gen.shared.builders"
local degrees = require "utils.math".degrees

local ball = b.circle(16)

local arm = b.rectangle(2, 13)
local arm1 = b.translate(arm, 0, -19.5)
local arm2 = b.translate(arm, 0, 22)
local arm3 = b.rectangle(2, 19)
arm3 = b.rotate(arm3, degrees(-30))
arm3 = b.translate(arm3, -12, 22)

ball = b.any{ball, arm1, arm2, arm3}
ball = b.translate(ball, 0, -28)

local balls = b.any{ball, b.rotate(ball, degrees(120)), b.rotate(ball, degrees(240))}

local small_circle = b.circle(48)
local big_circle = b.circle(54)
local ring = b.all{big_circle, b.invert(small_circle)}

local big_ball = b.any{balls, ring}

local big_arm1 = b.rectangle(6.75, 42.5)
big_arm1 = b.translate(big_arm1, 0, -74.25)
--local big_arm2 = b.rectangle(24, 242)
--big_arm2 = b.translate(big_arm2, 0, 174)

big_ball = b.any{big_ball, big_arm1, big_arm2}

big_ball = b.rotate(big_ball, degrees(-90))
big_ball = b.rotate(big_ball, math.atan2(54,210))
big_ball = b.translate(big_ball, 210, -54)

local big_balls = {}
local count = 12
local angle = 360 / count
local offset = (180 / count) + 90
for i = 0, count - 1 do
    local s =b.rotate(big_ball, degrees(i * angle ))
    table.insert(big_balls, s)
end

local big_balls = b.segment_pattern(big_balls)


local small_circle = b.circle(304.5)
local big_circle = b.circle(316.5) --342.5625
local ring = b.all{big_circle, b.invert(small_circle)}

local map = b.any{big_balls, ring}

local leg = b.rectangle(32,480)
local head = b.translate (b.oval(32, 64), 0, -64)
local body = b.translate (b.circle(64), 0, 64)

local count = 10
local angle = 360 / count
local list = { head, body }
for i = 1, (count / 2) - 1 do
    local shape = b.rotate(leg, degrees(i * angle))
    table.insert( list, shape )
end

local spider = b.any(list)
spider = b.scale(spider,.75,.75)

--map = b.any{map, spider}
map = b.translate(map, -30, 201)
map = b.scale(map, 12, 12)

return map
