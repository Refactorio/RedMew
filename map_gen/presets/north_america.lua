local b = require "map_gen.shared.builders"

local pic = require "map_gen.data.presets.north_america"
pic = b.decompress(pic)
local map = b.picture(pic)

-- this changes the size of the map
map = b.scale(map, 2, 2)

-- this moves the map, effectively changing the spawn point.
 map = b.translate(map, 0, -200)

-- this sets the tile outside the bounds of the map to deepwater, remove this and it will be void.
map = b.change_tile(map, false, "deepwater")

return map
