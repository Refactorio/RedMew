local _sin = math.sin
local _cos = math.cos

math.sin = function(x)
     return math.floor(_sin(x) * 10000000 + 0.5) / 10000000
end


math.cos = function(x)
     return math.floor(_cos(x) * 10000000 + 0.5) / 10000000
end
