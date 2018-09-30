--[[-- info
    Provides the ability to make a simple room with contents
]]

-- dependencies
local Template = require 'map_gen.Diggy.Template'
local Perlin = require 'map_gen.shared.perlin_noise'
local Event = require 'utils.event'
local Debug = require'map_gen.Diggy.Debug'
local Task = require 'utils.Task'
local Token = require 'utils.global_token'

-- this
local SimpleRoomGenerator = {}

-- https://hastebin.com/udakacavap.js
-- values are in the form {evolution, weight}
local biter_spawner = {
    {['Small Biter']    = {{0.0, 0.3}, {0.6, 0.0}}},
    {['Medium Biter']   = {{0.2, 0.0}, {0.6, 0.3}, {0.7, 0.1}}},
    {['Big Biter']      = {{0.5, 0.0}, {1.0, 0.4}}},
    {['Behemoth Biter'] = {{0.9, 0.0}, {1.0, 0.3}}},
}

local spitter_spawner = {
    {['Small Biter']      = {{0.0, 0.3}, {0.35, 0.0}}},
    {['Small Spitter']    = {{0.25, 0.0}, {0.5, 0.3}, {0.7, 0.0}}},
    {['Medium Spitter']   = {{0.4, 0.0}, {0.7, 0.3}, {0.9, 0.1}}},
    {['Big Spitter']      = {{0.5, 0.0}, {1.0, 0.4}}},
    {['Behemoth Spitter'] = {{0.9, 0.0}, {1.0, 0.3}}},
}

local function lerp(low, high, pos)
    local s = high[1] - low[1];
    local l = (pos - low[1]) / s;
    return (low[2] * (1-l)) + (high[2] * l)
end

-- gets the weight list
local function get_values(map, evo)
    local result = {}
    local sum = 0

    for _, data in pairs(map) do
        local list = data[2];
        local low = list[1];
        local high = list[#list - 1];

        for _, val in pairs(list) do
            if(val[1] <= evo and val[1] >  low[1]) then
                low = val;
            end
            if(val[1] >= evo and val[1] < high[1]) then
                high = val
            end
        end

        local val
        if (evo <= low[1]) then
            val = low[2]
        elseif (evo >= high[1]) then
            val = high[2];
        else
            val = lerp(low, high, evo)
        end
        sum = sum + val;

        result[data[1]] = val;
    end

    for index, data in pairs(results) do
        result[data] = result[data] / sum
    end

    return result;
end


local function get_first_player()
    for _, player in pairs(game.players) do
        return player
    end
end

local do_spawn_tile = Token.register(function(params)
    Template.insert(params.surface, {params.tile}, {})
end)

local do_mine = Token.register(function(params)
    local sand_rocks = params.surface.find_entities_filtered({position = params.position, name = 'sand-rock-big'})

    for _, rock in pairs(sand_rocks) do
        -- dangerous due to inventory, be cautious!
        get_first_player().mine_entity(rock, true)
    end

    if (0 == #sand_rocks) then
        Debug.printPosition(params.position, 'missing rock when trying to mine.')
    end
end)

local function handle_noise(name, surface, position)
    Task.set_timeout_in_ticks(1, do_mine, {surface = surface, position = position})

    if ('water' == name) then
        -- water is lower because for some odd reason it doesn't always want to mine it properly
        Task.set_timeout_in_ticks(5, do_spawn_tile, { surface = surface, tile = { name = 'deepwater-green', position = position}})
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
function SimpleRoomGenerator.register(cfg)
    local config = cfg.features.SimpleRoomGenerator

    local function get_noise(surface, x, y)
        local seed = surface.map_gen_settings.seed + surface.index
        return Perlin.noise(x * config.noise_variance, y * config.noise_variance, seed)
    end

    Event.add(Template.events.on_void_removed, function (event)
        local position = event.old_tile.position
        local distance = math.floor(math.sqrt(position.x^2 + position.y^2))

        if (distance < config.water_minimum_distance) then
            return
        end

        local noise = get_noise(event.surface, position.x, position.y)

        for _, noise_range in pairs(config.room_noise_ranges) do
            if (noise >= noise_range.min and noise <= noise_range.max) then
                handle_noise(noise_range.name, event.surface, position)
            end
        end
    end)

    if (config.enable_noise_grid) then
        Event.add(defines.events.on_chunk_generated, function (event)
            for x = event.area.left_top.x, event.area.left_top.x + 31 do
                for y = event.area.left_top.y, event.area.left_top.y + 31 do
                    Debug.print_grid_value(get_noise(event.surface, x, y), event.surface, {x = x, y = y})
                end
            end
        end)
    end
end

--[[--
    Initializes the Feature.

    @param config Table {@see Diggy.Config}.
]]
function SimpleRoomGenerator.initialize(config)

end

return SimpleRoomGenerator
