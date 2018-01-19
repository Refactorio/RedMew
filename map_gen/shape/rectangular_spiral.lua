require "map_genshared.compass"
require "map_genshared.chunk_utils"

local compass = Compass.new()
local pixels={}
pixels["-1,-1"] = true
width = 4

function build()
  local p = {-1,-1}
  local n = 1
  for x=1,300 do
    for i = 1, n do
     p[1] = p[1] + compass:get_direction()["x"]
     p[2] = p[2] + compass:get_direction()["y"]
     add(p)
    end
    compass:turn_left()
    n = n + 1
  end
end

local function onshape(p)
  x = math.floor(p[1]/32/width)
  y = math.floor(p[2]/32/width)


  if pixels[x .. "," .. y] ~= nil then
  end
  return pixels[x .. "," .. y] ~= nil
end

function add(p)
  pixels[p[1].. "," .. p[2]] = true
end


build()

function run_shape_module(event)
  if not onshape({event.area.left_top.x - width/2 * 32,event.area.left_top.y - width/2 * 32}) then
    removeChunk(event)
    return false
  end
end
