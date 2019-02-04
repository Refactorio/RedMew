local thickness = 72 -- change this to change the spiral thickness.

local inv_pi = 1 / math.pi
local thickness2 = thickness * 2
local sqrt = math.sqrt

return function(x, y)
    local d = sqrt(x * x + y * y)
    if d < 128 then
        return true
    end

    local angle = 1 + inv_pi * math.atan2(x, y)
    local offset = d + (angle * thickness)

    return offset % thickness2 >= thickness
end
