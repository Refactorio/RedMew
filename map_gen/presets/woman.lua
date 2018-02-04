-- Recommend to use generate, but generate_not_threaded may be useful for testing / debugging.
--require "map_gen.shared.generate_not_threaded"
require "map_gen.shared.generate"

local pic = require "map_gen.data.presets.woman"
local pic = decompress(pic)
local shape = picture_builder(pic)

local map = single_pattern_overlap_builder(shape, pic.width - 50, pic.height - 120)

map = translate(map, 135, -65)
--map = change_tile(map, false, "deepwater")

--map = scale(map, 2, 2)