-- Time Helper Module
-- Common Time functions
-- @author Denis Zholob (DDDGamer)
-- github: https://github.com/DDDGamer/factorio-dz-softmod
-- ======================================================= --

Time = {}

-- Rounding helper function
function round(number, precision)
   return math.floor(number*math.pow(10,precision)+0.5) / math.pow(10,precision)
end

-- Returns hours converted from game ticks
function Time.tick_to_hour(t)
  local time = game.speed * (t / 60) / 3600
  return round(time, 1)
end

-- Returns hours converted from game ticks
function Time.tick_to_min(t)
  local time = game.speed * (t / 60) / 60
  return round(time, 1)
end

return Time
