local b = require "map_gen.shared.builders"

local pic = require "map_gen.data.presets.creation_of_adam2"
pic = b.decompress(pic)

local shape = b.picture(pic)

--map = b.change_map_gen_collision_tile(map, "water-tile", "grass-1")

return shape