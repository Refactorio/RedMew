require "map_gen.shared.compass"
require "map_gen.shared.chunk_utils"

local compass = Compass.new()
local pixels = {}
pixels["-1,-1"] = true
local width = 4

local function add(p)
  pixels[p[1] .. "," .. p[2]] = true
end

local function build()
  local p = {-1, -1}
  local n = 1
  for x = 1, 300 do
    for i = 1, n do
      p[1] = p[1] + compass:get_direction()["x"]
      p[2] = p[2] + compass:get_direction()["y"]
      add(p)
    end
    compass:turn_left()
    n = n + 1
  end
end

build()

local offset = width * 0.5 * 32
local mult = 1 / (width * 32)

return function(x, y)
  x = math.floor((x - offset) * mult)
  y = math.floor((y - offset) * mult)

  return pixels[x .. "," .. y] ~= nil
end
