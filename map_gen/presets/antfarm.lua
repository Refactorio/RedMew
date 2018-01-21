map_gen_decoratives = false -- Generate our own decoratives
map_gen_rows_per_tick = 8 -- Inclusive integer between 1 and 32. Used for map_gen_threaded, higher numbers will generate map quicker but cause more lag.

-- Recommend to use generate, but generate_not_threaded may be useful for testing / debugging.
--require "map_gen.shared.generate_not_threaded"
require "map_gen.shared.generate"

local pic = require "map_gen.data.presets.antfarm"

local scale_factor = 12
local shape = picture_builder(pic)
shape = invert(shape)

local map = single_pattern_builder(shape, pic.width, pic.height)
map = translate(map, -12, 2)
map = scale(map, scale_factor, scale_factor)

--map = change_tile(map, false, "water")
--map = change_map_gen_collision_tile(map, "water-tile", "grass-1")

return map
