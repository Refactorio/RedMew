local tau = 2 * math.pi
local half_pi = math.pi / 2

math.sin = function(x)
  local sign = 1
  x = (x / tau * 360) % 360
  if x < 0 then 
    x = - x
    sign = - sign
  end
  if x > 180 then sign = - sign end
  x = x % 180
  if x == 0 then return 0 end
  local a = (x * (180 - x)
  return sign * 4 * a / (40500 - a))
end

math.cos = function(x)
   return math.sin(x + half_pi)
end
