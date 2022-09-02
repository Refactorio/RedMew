--[[-- info
    Provides the ability to make a simple room with contents
]]

-- dependencies
local Template = require 'map_gen.maps.black_forest.template'
local Event = require 'utils.event'
local Debug = require 'map_gen.maps.black_forest.debug'
local Task = require 'utils.task'
local Token = require 'utils.token'
local raise_event = script.raise_event
local pairs = pairs
local perlin_noise = require 'map_gen.shared.perlin_noise'.noise
local template_insert = Template.insert
local set_timeout_in_ticks = Task.set_timeout_in_ticks
-- this
local SimpleRoomGenerator = {}

local do_spawn_tile = Token.register(function(params)
    template_insert(params.surface, {params.tile}, {})
end)

local trees_lookup = Template.black_forest_trees

local do_mine = Token.register(function(params)
    local surface = params.surface
    local position = params.position
    local trees = surface.find_entities_filtered({position = position, name = trees_lookup})

    local tree_count = #trees
    if tree_count == 0 then
        return
    end

    for i = tree_count, 1, -1 do
        local tree = trees[i]
        tree.destroy{raise_destroy = true}
    end
end)

local function handle_noise(name, surface, position)
    set_timeout_in_ticks(1, do_mine, {surface = surface, position = position})

    if 'dirt' == name then
        return
    end

    if 'water' == name then
        -- water is slower because for some odd reason it doesn't always want to mine it properly
        set_timeout_in_ticks(4, do_spawn_tile, { surface = surface, tile = {name = 'water-green', position = position}})
        return
    end

    if 'deepwater' == name then
        -- water is slower because for some odd reason it doesn't always want to mine it properly
        set_timeout_in_ticks(4, do_spawn_tile, { surface = surface, tile = {name = 'deepwater-green', position = position}})
        return
    end

    error('No noise handled for type \'' .. name .. '\'')
end

--[[--
    Registers all event handlers.
]]
function SimpleRoomGenerator.register(config)
    local room_noise_minimum_distance_sq = config.room_noise_minimum_distance * config.room_noise_minimum_distance
    local noise_variance = config.noise_variance

    local seed
    local function get_noise(surface, x, y)
        seed = seed or surface.map_gen_settings.seed + surface.index + 100
        return perlin_noise(x * noise_variance, y * noise_variance, seed)
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
                handle_noise(noise_range.name, surface, {position.x +0.5 , position.y +0.5})
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

function SimpleRoomGenerator.get_extra_map_info()
    return 'Simple Room Generator, chopping around might open clearings!'
end

return SimpleRoomGenerator
