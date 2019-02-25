local Event = require 'utils.event'
local Game = require 'utils.game'

global.allowed_landfill_tiles = {}

Event.add(
    defines.events.on_player_built_tile,
    function(event)
        local item = event.item
        if not item then
            return
        end

        local item_name = item.name
        if item_name ~= 'landfill' then
            return
        end

        local allowed = global.allowed_landfill_tiles

        local new_tiles = {}
        for _, tile in ipairs(event.tiles) do
            local name = tile.old_tile.name
            if not allowed[name] then
                tile.name = name
                table.insert(new_tiles, tile)
            end
        end

        local count = #new_tiles
        if count == 0 then
            return
        end

        local surface = game.surfaces[event.surface_index]
        surface.set_tiles(new_tiles)

        local player = Game.get_player_by_index(event.player_index)
        player.insert {name = item_name, count = count}
    end
)

return function(allowed_set)
    global.allowed_landfill_tiles = allowed_set
end
