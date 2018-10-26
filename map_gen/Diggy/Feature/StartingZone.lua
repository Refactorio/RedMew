--[[-- info
    Provides the ability to create a pre-configured starting zone.
]]
-- dependencies
local Event = require 'utils.event'
local Token = require 'utils.global_token'
local Template = require 'map_gen.Diggy.Template'
local Debug = require 'map_gen.Diggy.Debug'
local DiggyCaveCollapse = require 'map_gen.Diggy.Feature.DiggyCaveCollapse'
local insert = table.insert
local random = math.random
local sqrt = math.sqrt
local floor = math.floor

-- this
local StartingZone = {}

--[[--
    Registers all event handlers.
]]
function StartingZone.register(config)
    local callback_token
    local starting_zone_size = config.starting_size

    local function on_chunk_generated(event)
        local start_point_area = {{-0.9, -0.9}, {0.9, 0.9}}
        local start_point_cleanup = {{-0.9, -0.9}, {1.9, 1.9}}
        local surface = event.surface

        -- hack to figure out whether the important chunks are generated via Diggy.Feature.RefreshMap.
        if (4 ~= surface.count_tiles_filtered({start_point_area, name = 'lab-dark-1'})) then
            return
        end

        -- ensure a clean starting point
        for _, entity in pairs(surface.find_entities_filtered({area = start_point_cleanup, type = 'resource'})) do
            entity.destroy()
        end

        local tiles = {}
        local rocks = {}

        local dirt_range = floor(starting_zone_size / 2)
        local rock_range = starting_zone_size - 2
        local stress_hack = floor(starting_zone_size / 10)

        for x = -starting_zone_size, starting_zone_size do
            for y = -starting_zone_size, starting_zone_size do
                local distance = floor(sqrt(x * x + y * y))

                if (distance < starting_zone_size) then
                    if (distance > dirt_range) then
                        insert(tiles, {name = 'dirt-' .. random(1, 7), position = {x = x, y = y}})
                    else
                        insert(tiles, {name = 'stone-path', position = {x = x, y = y}})
                    end

                    if (distance > rock_range) then
                        insert(rocks, {name = 'sand-rock-big', position = {x = x, y = y}})
                    end

                    -- hack to avoid starting area from collapsing
                    if (distance > stress_hack) then
                        DiggyCaveCollapse.stress_map_add(surface, {x = x, y = y}, -0.5)
                    end
                end
            end
        end

        Template.insert(event.surface, tiles, rocks)

        Event.remove_removable(defines.events.on_chunk_generated, callback_token)
    end

    callback_token = Token.register(on_chunk_generated)

    Event.add_removable(defines.events.on_chunk_generated, callback_token)
end

function StartingZone.on_init()
    local surface = game.surfaces.nauvis

    surface.daytime = 0.5
    surface.freeze_daytime = 1
    -- base factorio =                pollution_factor = 0.000015
    game.map_settings.enemy_evolution.pollution_factor = 0.000002
end


return StartingZone
