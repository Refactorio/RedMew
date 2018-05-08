map_gen_decoratives = false -- Generate our own decoratives
map_gen_rows_per_tick = 8 -- Inclusive integer between 1 and 32. Used for map_gen_threaded, higher numbers will generate map quicker but cause more lag.

-- Recommend to use generate, but generate_not_threaded may be useful for testing / debugging.
--require "map_gen.shared.generate_not_threaded"
require "map_gen.shared.generate"

local b = require "map_gen.shared.builders"

local pic = require "map_gen.data.presets.manhattan"
pic = b.decompress(pic)

local shape = b.picture(pic)
shape = b.translate(shape, 10, -96)
shape = b.scale(shape,2,2)
shape = b.rotate(shape, degrees(-22.5))

shape = b.change_tile(shape, false, "deepwater")

return shape