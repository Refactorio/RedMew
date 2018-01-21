map_gen_decoratives = false -- Generate our own decoratives
map_gen_rows_per_tick = 8 -- Inclusive integer between 1 and 32. Used for map_gen_threaded, higher numbers will generate map quicker but cause more lag.

-- Recommend to use generate, but generate_not_threaded may be useful for testing / debugging.
--require "map_gen.shared.generate_not_threaded"
require "map_gen.shared.generate"

map_gen_decoratives = true

local pic = require "map_gen.data.presets.biome_test"

local shape = picture_builder(pic)

--shape = change_tile(shape, false, "out-of-map")

return shape
