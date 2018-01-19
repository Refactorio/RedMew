require "map_gen.shared.generate"
require "map_gen.combined.grilledham_map_gen.builders"

local pic = require "map_gen.data.presets.cage"

local shape = picture_builder(pic.data, pic.width, pic.height)
shape = translate(shape, 10, -96)
shape = scale(shape,2,2)
--shape = rotate(shape, degrees(0))

-- shape = change_tile(shape, false, "deepwater")

return shape
