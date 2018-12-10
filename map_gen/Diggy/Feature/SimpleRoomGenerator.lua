--[[-- info
    Provides the ability to make a simple room with contents
]]

-- dependencies
local Template = require 'map_gen.Diggy.Template'
local Perlin = require 'map_gen.shared.perlin_noise'
local Event = require 'utils.event'
local Debug = require'map_gen.Diggy.Debug'
local Task = require 'utils.threading'
local Token = require 'utils.token'
local raise_event = script.raise_event

-- this
local SimpleRoomGenerator = {}

local do_spawn_tile = Token.register(function(params)
    Template.insert(params.surface, {params.tile}, {})
end)

local rocks_lookup = Template.diggy_rocks

local do_mine = Token.register(function(params)
    local surface = params.surface
    local position = params.position
    local rocks = surface.find_entities_filtered({position = position, name = rocks_lookup})

    local rock_count = #rocks
    if rock_count == 0 then
        return
    end

    for i = rock_count, 1, -1 do
        local rock = rocks[i]
        raise_event(defines.events.on_entity_died, {entity = rock})
        rock.destroy()
    end
end)

local function handle_noise(name, surface, position)
    Task.set_timeout_in_ticks(1, do_mine, {surface = surface, position = position})

    if ('water' == name) then
        -- water is slower because for some odd reason it doesn't always want to mine it properly
        Task.set_timeout_in_ticks(4, do_spawn_tile, { surface = surface, tile = {name = 'deepwater-green', position = position}})
        return
    end

    if ('dirt' == name) then
        return
    end

    error('No noise handled for type \'' .. name .. '\'')
end

--[[--
    Registers all event handlers.
]]
function SimpleRoomGenerator.register(config)
    local room_noise_minimum_distance_sq = config.room_noise_minimum_distance * config.room_noise_minimum_distance

    local seed
    local function get_noise(surface, x, y)
        seed = seed or surface.map_gen_settings.seed + surface.index + 100
        return Perlin.noise(x * config.noise_variance, y * config.noise_variance, seed)
    end

    Event.add(Template.events.on_void_removed, function (event)
        local position = event.position
        local x = position.x
        local y = position.y

        local distance_sq = x * x + y * y

        if (distance_sq <= room_noise_minimum_distance_sq) then
            return
        end

        local surface = event.surface
        local noise = get_noise(surface, x, y)

        for _, noise_range in pairs(config.room_noise_ranges) do
            if (noise >= noise_range.min and noise <= noise_range.max) then
                handle_noise(noise_range.name, surface, position)
            end
        end
    end)

    if (config.display_room_locations) then
        Event.add(defines.events.on_chunk_generated, function (event)
            local surface = event.surface
            local area = event.area

            for x = area.left_top.x, area.left_top.x + 31 do
                for y = area.left_top.y, area.left_top.y + 31 do
                    for _, noise_range in pairs(config.room_noise_ranges) do
                        local noise = get_noise(surface, x, y)
                        if (noise >= noise_range.min and noise <= noise_range.max) then
                            Debug.print_grid_value(noise_range.name, surface, {x = x, y = y}, nil, nil, true)
                        end
                    end
                end
            end
        end)
    end
end

function SimpleRoomGenerator.get_extra_map_info(config)
    return 'Simple Room Generator, digging around might open rooms!'
end

return SimpleRoomGenerator
