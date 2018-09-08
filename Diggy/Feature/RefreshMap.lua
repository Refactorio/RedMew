--[[-- info
    Provides the ability to refresh the map and generate darkness.
]]

-- dependencies
local Event = require 'utils.event'
local Template = require 'Diggy.Template'

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
                table.insert(tiles, {
                    name = tile,
                    position = {target_x, target_y}
                })
            end
        end

        Template.insert(event.surface, tiles)
    end)
end

--[[--
    Initializes the Feature.

    @param config Table {@see Diggy.Config}.
]]
function RefreshMap.initialize(config)

end

return RefreshMap
