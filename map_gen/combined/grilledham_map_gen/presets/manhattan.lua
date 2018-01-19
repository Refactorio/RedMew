require "map_gencombined.grilledham_map_gen.map_gen"
require "map_gencombined.grilledham_map_gen.builders"

local pic = require "map_gencombined.grilledham_map_gen.data.manhattan"

local shape = picture_builder(pic.data, pic.width, pic.height)
shape = translate(shape, 10, -96)
shape = scale(shape,2,2)
shape = rotate(shape, degrees(-22.5))

shape = change_tile(shape, false, "deepwater")

return shape