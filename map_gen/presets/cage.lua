map_gen_decoratives = false -- Generate our own decoratives
map_gen_rows_per_tick = 4 -- Inclusive integer between 1 and 32. Used for map_gen_threaded, higher numbers will generate map quicker but cause more lag.

-- Recommend to use generate, but generate_not_threaded may be useful for testing / debugging.
--require "map_gen.shared.generate_not_threaded"
require "map_gen.shared.generate"

local pic = require "map_gen.data.presets.cage"

local shape = picture_builder(pic)
shape = translate(shape, 10, -96)
shape = scale(shape,2,2)
--shape = rotate(shape, degrees(0))

-- shape = change_tile(shape, false, "deepwater")

return shape
