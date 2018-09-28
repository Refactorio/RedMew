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

  return sign * 4 * x *(180 - x) / (40500 - (x * (180 - x)))
end

math.cos = function(x)
   return math.sin(x + half_pi)
end
