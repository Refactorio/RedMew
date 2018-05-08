map_gen_decoratives = false -- Generate our own decoratives
map_gen_rows_per_tick = 8 -- Inclusive integer between 1 and 32. Used for map_gen_threaded, higher numbers will generate map quicker but cause more lag.

-- Recommend to use generate, but generate_not_threaded may be useful for testing / debugging.
--require "map_gen.shared.generate_not_threaded"
require "map_gen.shared.generate"

local b = require "map_gen.shared.builders"

local pic = require "map_gen.data.presets.antfarm"
pic = b.decompress(pic)

local scale_factor = 12
local shape = b.picture(pic)
--shape = b.invert(shape)

local map = b.single_pattern(shape, pic.width, pic.height)
map = b.translate(map, -12, 2)
map = b.scale(map, scale_factor, scale_factor)

return map
