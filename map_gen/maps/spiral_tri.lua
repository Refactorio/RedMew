return function(x, y)
    local distance = math.sqrt(x * x + y * y)
    if distance > 128 then
        local angle = (180 + math.deg(math.atan2(x, y))) * 3

        local offset = distance * 0.75
        if angle ~= 0 then
            offset = offset + angle / 3.75
        end
        --if angle ~= 0 then offset = offset + angle /1.33333333 end

        if offset % 96 < 48 then
            local offset2 = distance * 0.125
            if angle ~= 0 then
                offset2 = offset2 - angle / 3.75
            end

            return offset2 % 96 >= 80
        end
    end

    return true
end
