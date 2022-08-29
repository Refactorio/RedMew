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
function RefreshMap.register(config)
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
                local target_x_1000 = target_x % 1000

                if (config.river) then
                    if target_y > -8 and target_y < 9 then
                        tile = 'deepwater-green'
                    end
                    if target_y < -6 and target_y > -10 and target_x_1000 > 749 then
                        tile = 'dirt-6'
                        event.surface.create_entity{name='tree-01', position={target_x +0.5, target_y+0.5}}
                    end
                    if target_y < -7 and target_y > -10 and target_x_1000 < 251 then
                        tile = 'dirt-6'
                        event.surface.create_entity{name='tree-01', position={target_x +0.5, target_y+0.5}}
                    end
                    if target_y < -6 and target_y > -10 and target_x_1000 > 249 and target_x_1000 < 501 then
                        tile = 'dirt-6'
                        event.surface.create_entity{name='tree-01', position={target_x +0.5, target_y+0.5}}
                    end
                    if target_y < -7 and target_y > -10 and target_x_1000 > 499 and target_x_1000 < 751 then
                        tile = 'dirt-6'
                        event.surface.create_entity{name='tree-01', position={target_x +0.5, target_y+0.5}}
                    end

                    if target_y < 10 and target_y > 7 and target_x_1000 > 699 +25 then
                        tile = 'dirt-6'
                        event.surface.create_entity{name='tree-01', position={target_x +0.5, target_y+0.5}}
                    end
                    if target_y < 10 and target_y > 7 and target_x_1000 < 51 -25 then
                        tile = 'dirt-6'
                        event.surface.create_entity{name='tree-01', position={target_x +0.5, target_y+0.5}}
                    end
                    if target_y < 10 and target_y > 7 and target_x_1000 > 199 +25 and target_x_1000 < 551 -25 then
                        tile = 'dirt-6'
                        event.surface.create_entity{name='tree-01', position={target_x +0.5, target_y+0.5}}
                    end
                    if target_y < 10 and target_y > 6 and target_x_1000 > 549 -25 and target_x_1000 < 701 +25 then
                        tile = 'dirt-6'
                        event.surface.create_entity{name='tree-01', position={target_x +0.5, target_y+0.5}}
                    end
                    if target_y < 10 and target_y > 6 and target_x_1000 > 49 -25 and target_x_1000 < 201 +25 then
                        tile = 'dirt-6'
                        event.surface.create_entity{name='tree-01', position={target_x +0.5, target_y+0.5}}
                    end--[[--]]
                end
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
