--[[-- info
    Provides the ability to refresh the map and generate darkness.
]]

-- dependencies
local Event = require 'utils.event'

-- this
local RefreshMap = {}

--[[--
    Registers all event handlers.
]]
function RefreshMap.register()
    Event.add(defines.events.on_chunk_generated, function (event)
        local tiles = {}

        local left_top = event.area.left_top
        local left_top_x = left_top.x
        local left_top_y = left_top.y

        local count = 0
        for x = 0, 31, 1 do
            for y = 0, 31, 1 do
                local target_x = left_top_x + x
                local target_y = left_top_y + y
                local tile = 'out-of-map'

                if target_x > -2 and target_x < 1 and target_y > -2 and target_y < 1 then
                    tile = 'lab-dark-1'
                end

                count = count + 1
                tiles[count] = {
                    name = tile,
                    position = {x = target_x, y = target_y}
                }
            end
        end

        event.surface.set_tiles(tiles)
    end)
end

return RefreshMap
