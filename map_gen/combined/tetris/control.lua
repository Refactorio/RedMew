local Event = require 'utils.event'

local Map = require 'map_gen.combined.tetris.shape'
local Tetrimino = require 'map_gen.combined.tetris.tetrimino'(Map)

Event.on_nth_tick(61, function() 
    if game.tick == nil then return end
end)


return Map.get_map()