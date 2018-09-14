--[[-- info
    Provides the ability to create a pre-configured starting zone.
]]

-- dependencies
local Event = require 'utils.event'
local Token = require 'utils.global_token'
local Mask = require 'Diggy.Mask'
local Template = require 'Diggy.Template'

-- this
local StartingZone = {}

--[[--
    Registers all event handlers.
]]
function StartingZone.register(config)
    local callback_token

    local function on_chunk_generated(event)
        local start_point_area = {{-1, -1}, {0, 0}}

        -- hack to figure out whether the important chunks are generated via Diggy.Feature.RefreshMap.
        if (4 ~= #event.surface.find_tiles_filtered({start_point_area, name='lab-dark-1'})) then
            return
        end

        -- ensure a clean starting point
        for _, entity in pairs(event.surface.find_entities(start_point_area)) do
            if (entity.type ~= 'player') then
                entity.destroy()
            end
        end

        local tiles = {}
        local rocks = {}

        Mask.circle(0, 0, config.features.StartingZone.starting_size, function(x, y, tile_distance_to_center)
            table.insert(tiles, {name = 'dirt-' .. math.random(1, 7), position = {x = x, y = y}})

            if (tile_distance_to_center > config.features.StartingZone.starting_size - 2) then
                table.insert(rocks, {name = 'sand-rock-big', position = {x = x, y = y}})
            end
        end)

        Template.insert(event.surface, tiles, rocks)

        Event.remove_removable(defines.events.on_chunk_generated, callback_token)
    end

    callback_token = Token.register(on_chunk_generated)

    Event.add_removable(defines.events.on_chunk_generated, callback_token)
end

--[[--
    Initializes the Feature.

    @param config Table {@see Diggy.Config}.
]]
function StartingZone.initialize(config)
    local surface = game.surfaces.nauvis

    surface.daytime = config.features.StartingZone.daytime
    surface.freeze_daytime = 1

end

return StartingZone
