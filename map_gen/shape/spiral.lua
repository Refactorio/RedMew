local thickness = 72 -- change this to change the spiral thickness.

local inv_pi = 1 / math.pi
local thickness2 = thickness * 2

return function(x, y)
    local d_sq = x * x + y * y
    if d_sq < 16384 then --d < 128
        return true
    end

    local angle = 1 + inv_pi * math.atan2(x, y)
    local offset = d + (angle * thickness)

    return offset % thickness2 >= thickness
end
