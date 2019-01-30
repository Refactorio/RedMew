local abs = math.abs
return function(x, y)
    local abs_x = abs(x) - 0.5
    local abs_y = abs(y) - 0.5
    if (abs_y % 4 == 0) or (abs_x % 4 == 0) then -- Between quadrants create land
        if (abs_x <= 2 and abs_y <= 2) then --Spawn
            return true
        elseif (abs_x <= 23 and abs_y <= 23) and not (abs_x <= 2 and abs_y <= 2) then -- Around spawn, inbetween the quadrants
            return false
        elseif ((abs_x <= 2 and abs_y % 4 == 0) or abs_x == 9 or abs_x == 10 or abs_x == 17 or abs_x == 18) or ((abs_y <= 2 and abs_x % 4 == 0) or abs_y == 9 or abs_y == 10 or abs_y == 17 or abs_y == 18) then -- connections
            return true
        end
    end
    if abs_x <= 23  or abs_y <= 23 then -- Between quadrants remove land
        return false
    end
    return true
end

--9 + 10, 17 + 18