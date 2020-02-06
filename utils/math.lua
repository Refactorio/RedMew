--luacheck: globals math
local _sin = math.sin
local _cos = math.cos

math.sqrt2 = math.sqrt(2)
math.inv_sqrt2 = 1 / math.sqrt2
math.tau = 2 * math.pi

math.sin = function(x)
    return math.floor(_sin(x) * 10000000 + 0.5) / 10000000
end

math.cos = function(x)
    return math.floor(_cos(x) * 10000000 + 0.5) / 10000000
end

-- rounds number (num) to certain number of decimal places (idp)
math.round = function(num, idp)
    local mult = 10 ^ (idp or 0)
    return math.floor(num * mult + 0.5) / mult
end

math.clamp = function(num, min, max)
    if num < min then
        return min
    elseif num > max then
        return max
    else
        return num
    end
end

--- Takes two points and calculates the slope of a line
-- @param x1, y1 numbers - cordinates of a point on a line
-- @param x2, y2 numbers - cordinates of a point on a line
-- @return number - the slope of the line
math.calculate_slope = function(x1, y1, x2, y2)
    return math.abs((y2 - y1) / (x2 - x1))
end

--- Calculates the y-intercept of a line
-- @param x, y numbers - coordinates of point on line
-- @param slope number - the slope of a line
-- @return number - the y-intercept of a line
math.calculate_y_intercept = function(x, y, slope)
    return y - (slope * x)
end

local deg_to_rad = math.tau / 360
math.degrees = function(angle)
    return angle * deg_to_rad
end

return math
