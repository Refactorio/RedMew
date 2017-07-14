--Author Valansch



Compass = {
  east={x=1,y=0,next="north"},
  north={x=0,y=-1,next="west"},
  west={x=-1,y=0,next="south"},
  south={x=0,y=1,next="east"},
  direction="west"}
function Compass.turn()
  Compass.direction=Compass[Compass.direction].next
end
function Compass.getdirection()
 return Compass[Compass.direction]
end

--spiral
Spiral = {Pixels={}, width = 4, size = 10}
function Spiral.onshape(p)
  x = math.floor(p[1]/32/Spiral.width)
  y = math.floor(p[2]/32/Spiral.width)
  return Spiral.Pixels[x .. "," .. y] ~= nil
end
function Spiral.add(p)
  Spiral.Pixels[p[1].. "," .. p[2]] = true
end
function Spiral.takesteps(p, n)
  direction = Compass.getdirection()
  for i = 1, n do
   p[1] = p[1] + direction["x"]
   p[2] = p[2] + direction["y"]
   Spiral.add(p)
  end
  return p
end
function Spiral.build()
 p = {-1,-1}
 Spiral.add(p)
 for i = 1, 100 do
    p = Spiral.takesteps(p, i)
    Compass.turn()
 end
end
