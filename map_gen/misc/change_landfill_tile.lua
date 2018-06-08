local Event = require 'utils.event'

local tile

Event.add(
    defines.events.on_player_built_tile,
    function(event)
        local item = event.item
        if not item or not item.valid then
            return
        end

        if event.item.name == 'landfill' then
            local tiles = event.tiles
            for i = 1, #tiles do
                tiles[i].name = tile
            end
            local surface = game.surfaces[event.surface_index]
            surface.set_tiles(tiles)
        end
    end
)

return function(tile_name)
    tile = tile_name or 'sand-1'
end
