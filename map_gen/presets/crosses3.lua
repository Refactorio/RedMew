map_gen_decoratives = false -- Generate our own decoratives
map_gen_rows_per_tick = 8 -- Inclusive integer between 1 and 32. Used for map_gen_threaded, higher numbers will generate map quicker but cause more lag.

-- Recommend to use generate, but generate_not_threaded may be useful for testing / debugging.
--require "map_gen.shared.generate_not_threaded"
require "map_gen.shared.generate"

local scale_factor = 64

local pic = require "map_gen.data.presets.crosses3"
pic = decompress(pic)

local shape = picture_builder(pic)
shape = scale(shape, scale_factor, scale_factor)

local map = single_pattern_builder(shape, (pic.width - 24.5 ) * scale_factor + 6, (pic.height - 21.5) * scale_factor  - 6)
map = rotate(map, degrees(45))
map = translate(map, 48, -176)

return map