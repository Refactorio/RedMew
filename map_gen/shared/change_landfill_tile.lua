local Event = require 'utils.event'

local replacement_tiles
local tile_count
local random = math.random

Event.add(
    defines.events.on_player_built_tile,
    function(event)
        local item = event.item
        if not item then
            return
        end

        if item.name == 'landfill' then
            local tiles = event.tiles
            for i = 1, #tiles do
                tiles[i].name = replacement_tiles[random(1, tile_count)]
            end

            local surface = game.surfaces[event.surface_index]
            surface.set_tiles(tiles)
        end
    end
)

return function(tiles)
    replacement_tiles = tiles or {'sand-1'}
    tile_count = #replacement_tiles
end
