--[[-- info
    Provides the ability to refresh the map and generate darkness.
]]

-- dependencies
local Event = require 'utils.event'
local insert = table.insert

-- this
local RefreshMap = {}

--[[--
    Registers all event handlers.
]]
function RefreshMap.register(config)
    Event.add(defines.events.on_chunk_generated, function (event)
        local tiles = {}

        for x = 0, 31, 1 do
            for y = 0, 31, 1 do
                local target_x = event.area.left_top.x + x
                local target_y = event.area.left_top.y + y
                local tile = 'out-of-map'

                if (target_x < 1 and target_y < 1 and target_x > -2 and target_y > -2) then
                    tile = 'lab-dark-1'
                end

                insert(tiles, {
                    name = tile,
                    position = {x = target_x, y = target_y}
                })
            end
        end

        event.surface.set_tiles(tiles)
    end)
end

return RefreshMap
