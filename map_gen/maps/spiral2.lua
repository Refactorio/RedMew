return function(x, y)
    local distance = math.sqrt(x * x + y * y)
    if distance > 128 then
        local angle = 180 + math.deg(math.atan2(x, y))

        local offset = distance
        local offset2 = distance
        if angle ~= 0 then
            offset2 = offset - angle / 3.75
            offset = offset + angle / 3.75
        end
        --if angle ~= 0 then offset = offset + angle /1.33333333 end

        if offset % 96 < 64 then
            return offset2 % 96 >= 64
        end
    end

    return true
end
