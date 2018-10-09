local _sin = math.sin
local _cos = math.cos

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


math.sqrt2 = math.sqrt(2)
math.inv_sqrt2 = 1 / math.sqrt2

return math
