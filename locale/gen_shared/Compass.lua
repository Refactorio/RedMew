--Author Valansch

Compass = {}
Compass.__index = Compass
Compass.north={x=0,y=-1,next="west"}
Compass.west={x=-1,y=0,next="south"}
Compass.south={x=0,y=1,next="east"}
Compass.east={x=1,y=0,next="north"}

function Compass.new(start_direction)
  local self = setmetatable({}, Compass)
  self.direction = start_direction or "north"
  return self
end
function Compass:turn_left()
  self.direction= self:get_direction().next
end

function Compass:get_direction()
  return self[self.direction]
end


function Compass:turn_right()
  self:turn()
  self:turn()
  self:turn()
end
function Compass:turn_around()
  self:turn()
  self:turn()
end
