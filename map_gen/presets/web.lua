local b = require "map_gen.shared.builders"
local degrees = require "utils.math".degrees

local stripe_thickness = 24
local stripe_distance = 384

local stripes = b.throttle_y(b.full_shape,stripe_thickness,stripe_distance)
local joint = b.rectangle(64)
joint = b.rotate(joint,degrees(45))
joint = b.translate(joint, 0, stripe_thickness / 2)
local joints = b.single_y_pattern(joint, stripe_distance)

stripes = b.any{stripes, joints}

local lines = {}
local count = 8
local angle = 360 / count
local offset = (180 / count) + 90
for i = 0, count - 1 do
    local line =b.rotate(stripes, degrees(i * angle + offset))
    table.insert(lines, line)
end

local web = b.segment_pattern(lines)
web = b.rotate(web, degrees(180 / count))

local path = b.path(stripe_thickness)

local leg = b.rectangle(32,480)
local head = b.translate (b.oval(32, 64), 0, -64)
local body = b.translate (b.circle(64), 0, 64)

count = 10
angle = 360 / count
local list = { head, body }
for i = 1, (count / 2) - 1 do
    local shape = b.rotate(leg, degrees(i * angle))
    table.insert( list, shape )
end

local spider = b.any(list)
spider = b.scale(spider,2,2)

local e = b.empty_shape
local function s(r)
    return b.rotate(spider, degrees(r))
end

local pattern =
{
    {e     , s(90) , e     , s(0) , e      , s(270)},
    {s(0)  , e     , e     , e     , e     , e     },
    {e     , e     , s(45) , e     , s(315), e     },
    {s(90) , e     , e     , e     , e     , e     },
    {e     , e     , s(135), e     , s(225), e     },
    {s(180), e     , e     , e     , e     , e     },
}

local spiders = b.grid_pattern(pattern, 6, 6, 820, 820)

local map = b.any{ web, path, b.rotate(path, degrees(45)), spiders }

local start = b.circle(150)
map = b.choose(start, b.full_shape, map)

--map = b.scale(map, 0.5, 0.5)
return map
