-- Author: flowild

local arm_width = 96

local function is_on_spiral(x, y, distance, angle_offset)
    local angle = angle_offset + math.deg(math.atan2(x, y))

    local offset = distance
    if angle ~= 0 then
        offset = offset + angle / 3.75 * 2
    end
    return offset % 96 * 2 >= 48 * 2
end

return function(x, y)
    local pseudo_x = x / (arm_width / 48)
    local pseudo_y = y / (arm_width / 48)
    local distance = math.sqrt(pseudo_x * pseudo_x + pseudo_y * pseudo_y)

    return not (distance > 100 and not is_on_spiral(x, y, distance, 0))
end
