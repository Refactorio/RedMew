-- Recommend to use generate, but generate_not_threaded may be useful for testing / debugging.
require "map_gen.shared.generate_not_threaded"
--require "map_gen.shared.generate"

local pic = require "map_gen.data.presets.plus" --or whatever you called it in data->presets
local pic = decompress(pic)
local map = picture_builder(pic)

map = single_pattern_builder(map, pic.width-1, pic.height-1)

map = translate(map, 86, 0)

-- uncomment the line below to change the size of the map scale(x, y)
map = scale(map, 1.5, 1.5)

return map