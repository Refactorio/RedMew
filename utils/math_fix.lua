local _sin = math.sin
local _cos = math.cos

math.sin = function(x)
  local sign = 1
  x = x % 360
  if x < 0 then 
    x = - x
    sign = - sign
  end
  if x > 180 then sign = - sign end
  x = x % 180
  if x == 0 then return 0 end

  return sign * 4 * x *(180 - x) / (40500 - (x * (180 - x)))
end

math.cos = function(x)
   return math.sin(x + 90)
end
