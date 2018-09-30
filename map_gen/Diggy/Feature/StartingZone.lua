--[[-- info
    Provides the ability to create a pre-configured starting zone.
]]

-- dependencies
local Event = require 'utils.event'
local Token = require 'utils.global_token'
local Mask = require 'map_gen.Diggy.Mask'
local StressMap = require 'map_gen.Diggy.StressMap'
local Template = require 'map_gen.Diggy.Template'
local Debug = require 'map_gen.Diggy.Debug'

-- this
local StartingZone = {}

--[[--
    Registers all event handlers.
]]
function StartingZone.register(config)
    local callback_token
    local starting_zone_size = config.features.StartingZone.starting_size

    local function on_chunk_generated(event)
        local start_point_area = {{-1, -1}, {0, 0}}

        -- hack to figure out whether the important chunks are generated via Diggy.Feature.RefreshMap.
        if (4 ~= event.surface.count_tiles_filtered({start_point_area, name='lab-dark-1'})) then
            return
        end

        -- ensure a clean starting point
        for _, entity in pairs(event.surface.find_entities_filtered({area = start_point_area, type = 'resource'})) do
            entity.destroy()
        end

        local tiles = {}
        local rocks = {}

        Mask.circle(0, 0, starting_zone_size, function(x, y, tile_distance_to_center)
            if (tile_distance_to_center > math.floor(starting_zone_size / 2)) then
                table.insert(tiles, {name = 'dirt-' .. math.random(1, 7), position = {x = x, y = y}})
            else
                table.insert(tiles, {name = 'stone-path', position = {x = x, y = y}})
            end

            if (tile_distance_to_center > starting_zone_size - 2) then
                table.insert(rocks, {name = 'sand-rock-big', position = {x = x, y = y}})
            end

            if (tile_distance_to_center > math.floor(starting_zone_size / 10)) then
                Mask.blur(x, y, -0.3, function (x, y, fraction)
                    StressMap.add(event.surface, {x = x, y = y}, fraction)
                end)
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
