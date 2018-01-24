map_gen_decoratives = false -- Generate our own decoratives
map_gen_rows_per_tick = 8 -- Inclusive integer between 1 and 32. Used for map_gen_threaded, higher numbers will generate map quicker but cause more lag.

-- Recommend to use generate, but generate_not_threaded may be useful for testing / debugging.
--require "map_gen.shared.generate_not_threaded"
require "map_gen.shared.generate"

local pic = require "map_gen.data.presets.broken_web"
pic = decompress(pic)

local shape = picture_builder(pic)
shape = invert(shape)

local map = single_pattern_builder(shape, pic.width, pic.height - 1)
map = translate(map, 10, -27)
map = scale(map, 12, 12)

return map