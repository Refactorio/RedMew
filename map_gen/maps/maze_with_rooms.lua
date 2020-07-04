local Event = require 'utils.event'
local Global = require 'utils.global'
local RS = require 'map_gen.shared.redmew_surface'
local b = require 'map_gen.shared.builders'
local MGSP = require 'resources.map_gen_settings'
RS.set_map_gen_settings(
    {
        MGSP.ore_oil_none
        --MGSP.peaceful_mode_on
        --MGSP.water_none
    }
)

-- Height and width should always be even numbers
local maze_width = 194
local maze_height = 194
-- room_sizes must always be odd, and they must always be smaller than the map
local min_room_size = 5
local max_room_size = 21
local spawn_room_size = 9
-- Number of rooms to try to place, if a room overlaps another one it will be skipped meaning this is the max
local num_room_attempts = 1500
-- The number of extra connections to try to add after the map is already fully connected
-- set to 0 for no loops, higher numbers will make more loops
local extra_connection_attempts = 40
-- The number of factorio tiles per maze tile
local tile_scale = 14
-- The ore probabilities
-- Change weight to edit how likely ores are to spawn at every dead end
value = b.exponential_value
local ores = {
    {letter = 'i', resource = 'iron-ore', value = value(300, 0.75 * 5, 1.1), weight = 16},
    {letter = 'c', resource = 'copper-ore', value = value(200, 0.75 * 5, 1.1), weight = 10},
    {letter = 's', resource = 'stone', value = value(150, 0.3 * 5, 1.05), weight = 8},
    {letter = 'f', resource = 'coal', value = value(200, 0.8 * 5, 1.075), weight = 8},
    {letter = 'u', resource = 'uranium-ore', value = value(100, 0.3 * 5, 1.025), weight = 3},
    {letter = 'o', resource = 'crude-oil', value = value(10000, 50 * 5, 1.025), weight = 4},
    {letter = ' ', weight = 0} -- No ore
}

local random

local total_ore_weight = 0
for _, v in ipairs(ores) do
    total_ore_weight = total_ore_weight + v.weight
    v.accumulated_weight = total_ore_weight
end
local function get_random_ore_letter()
    local r = random(total_ore_weight)
    for _, v in ipairs(ores) do
        if r <= v.accumulated_weight then
            return v.letter
        end
    end
    error('the random number ' .. r .. ' did not result in any ore given the weights')
end

-- A number that keeps track of which region of the map something is.
-- When adding rooms and mazes, a region that is connected will have the same number on all its tiles
-- Used when connecting regions later on
local region_index = 1

local function shuffle(t)
    for i = 1, #t do
        local j = random(1, #t)
        local tmp = t[i]
        t[i] = t[j]
        t[j] = tmp
    end
    return t
end
-- builds a width-by-height grid of false
local function initialize_grid(w, h)
    local a = {}
    for i = 1, h do
        table.insert(a, {})
        for j = 1, w do
            table.insert(a[i], false)
        end
    end
    return a
end

-- average of a and b
local function avg(c, d)
    return (c + d) / 2
end

local dirs = {
    {x = 0, y = -2}, -- north
    {x = 2, y = 0}, -- east
    {x = -2, y = 0}, -- west
    {x = 0, y = 2} -- south
}

-- Adds perfect mazes in the remaining space of the map, each new number gets a unique region index
local function fill_with_mazes(map)
    local h = #map
    local w = #map[1]

    local walk
    walk = function(x, y)
        map[y][x] = region_index

        local d = {1, 2, 3, 4}
        shuffle(d)
        for i, dirnum in pairs(d) do
            local xx = x + dirs[dirnum].x
            local yy = y + dirs[dirnum].y
            if map[yy] and map[yy][xx] == false then
                map[avg(y, yy)][avg(x, xx)] = region_index
                walk(xx, yy)
            end
        end
    end
    for y = 1, #map, 2 do
        for x = 1, #map[y], 2 do
            if map[y][x] == false then
                walk(x, y)
                region_index = region_index + 1
            end
        end
    end
end

local function print_map(map)
    local s = ''
    for i = 1, #map[1] + 2 do
        s = s .. '+'
    end
    print(s)
    s = ''
    for y = 1, #map do
        s = s .. '+'
        for x = 1, #(map[y]) do
            if map[y][x] == true then
                s = s .. ' '
            elseif map[y][x] == false then
                --s = s .. '■'
                s = s .. 'X'
            elseif not tonumber(map[y][x]) then
                --s = s .. ' '
                s = s .. map[y][x]
            else
                --s = s .. map[y][x]
                s = s .. ' '
            end
        end
        s = s .. '+'
        print(s)
        s = ''
    end
    for i = 1, #map[1] + 2 do
        s = s .. '+'
    end
    print(s)
end

-- Places a room if it fits in the map, each tile in the room will get a unique number from the region index
local function try_place_room(map, top_left_x, top_left_y, room_size)
    for y = top_left_y, top_left_y + room_size - 1 do
        if not map[y] then
            return
        end
        for x = top_left_x, top_left_x + room_size - 1 do
            if map[y][x] ~= false then
                return
            end
        end
    end
    for y = top_left_y, top_left_y + room_size - 1 do
        for x = top_left_x, top_left_x + room_size - 1 do
            map[y][x] = region_index
        end
    end
    region_index = region_index + 1
end

-- Attempts to place num_room_attemts number of rooms at random sizes, rooms are always placed at odd cordinates
local function add_rooms(map, num_room_attempts2, min_room_size2, max_room_size2)
    -- room_size must be odd
    for attempt = 1, num_room_attempts2 do
        -- Generates a random odd number between min_room_size and max_room_size (inclusive both)
        local room_size2 = min_room_size2 + random(0, (max_room_size2 - min_room_size2) / 2) * 2
        -- Generates a random odd top_left corner cordinate which would fit the room within the map
        local x = random(1, (#map[1] - room_size2 + 2) / 2) * 2 - 1
        local y = random(1, (#map - room_size2 + 2) / 2) * 2 - 1
        try_place_room(map, x, y, room_size2)
    end
end

-- Adds a room with size spawn_room_size in the center.
-- If it happens to be an even coordinate the room must be shifted one step to be at an odd
local function add_spawn_room(map)
    local room_size = spawn_room_size
    local center_x = (maze_width + 1) / 2
    local center_y = (maze_height + 1) / 2
    local room_radius = (room_size - 1) / 2
    local x = math.floor(center_x - room_radius)
    local y = math.floor(center_y - room_radius)
    if x % 2 == 0 then
        x = x + 1
    end
    if y % 2 == 0 then
        y = y + 1
    end

    try_place_room(map, x, y, room_size)
    --[[
    local cx = math.floor(center_x)
    local cy = math.floor(center_y)
    map[cy + 1][cx + 1] = 'i'
    map[cy - 1][cx + 1] = 'c'
    map[cy + 1][cx - 1] = 's'
    map[cy - 1][cx - 1] = 'f'

    ]]
end

-- Connects all different regions by making random walls between different regions into ground
local function connect_regions(map, extra_connection_attempts2)
    -- Returns false if the pos is not a connector (wall with 2 different regions next to it)
    -- Returns a table with the two neigbours if it is a connector
    local function check_connector(x, y)
        -- Check if there is a wall
        if map[y][x] ~= false then
            return false
        end
        local is_connector = false
        local neighbour_regions = {}
        for _, dir in ipairs(dirs) do
            local xx = x + dir.x / 2
            local yy = y + dir.y / 2
            if map[yy] ~= nil and map[yy][xx] ~= nil then
                local t = map[yy][xx]
                if t ~= false then
                    if #neighbour_regions == 0 then
                        neighbour_regions[1] = t
                    else
                        if neighbour_regions[1] ~= t then
                            neighbour_regions[2] = t
                            is_connector = true
                        end
                    end
                end
            end
        end
        if not is_connector then
            return false
        end
        return neighbour_regions
    end
    -- An array of all currently connected regions
    local connected_regions = {}
    local function is_connected(region_id)
        for _, v in pairs(connected_regions) do
            if v == region_id then
                return true
            end
        end
        return false
    end
    local function set_connected(region_id)
        connected_regions[#connected_regions + 1] = region_id
    end
    -- A list of all possible connectors
    local connectors = {}
    for y = 1, #map do
        local start_x = 2
        local end_x = #map[y]
        if y % 2 == 0 then
            start_x = start_x - 1
            end_x = end_x + 1
        end
        for x = start_x, end_x, 2 do
            local neighbours = check_connector(x, y)
            if neighbours then
                --connectors[neighbours] = {x = x, y = y}
                connectors[#connectors + 1] = {neighbours = neighbours, pos = {x = x, y = y}}
            end
        end
    end
    -- Returns a copy of connectors filtered to only contain connectors that would connect a new region
    -- i.e connects a connected region and an unconnected region
    local function find_possible_connectors()
        local possible_connectors = {}
        for _, connector in ipairs(connectors) do
            local neighbours = connector.neighbours
            local pos = connector.pos
            if is_connected(neighbours[1]) and not is_connected(neighbours[2]) then
                possible_connectors[#possible_connectors + 1] = connector
            end
            if is_connected(neighbours[2]) and not is_connected(neighbours[1]) then
                possible_connectors[#possible_connectors + 1] = connector
            end
        end
        return possible_connectors
    end
    set_connected(map[1][1])
    local possible_connectors = find_possible_connectors()
    while #possible_connectors > 0 do
        local connector = possible_connectors[random(#possible_connectors)]
        local neighbours = connector.neighbours
        if is_connected(neighbours[1]) then
            set_connected(neighbours[2])
        end
        if is_connected(neighbours[2]) then
            set_connected(neighbours[1])
        end
        local pos = connector.pos
        map[pos.y][pos.x] = true
        possible_connectors = find_possible_connectors()
    end
    -- Add extra connections to make it imperfect
    for i = 1, extra_connection_attempts2 do
        local connector = connectors[random(#connectors)]
        local pos = connector.pos
        map[pos.y][pos.x] = true
    end
end

local function get_neighbours_with_ground(map, x, y)
    local neighbours_with_ground = {}
    for _, dir in pairs(dirs) do
        local xx = x + dir.x / 2
        local yy = y + dir.y / 2
        if map[yy] and map[yy][xx] then
            neighbours_with_ground[#neighbours_with_ground + 1] = {x = xx, y = yy}
        end
    end
    return neighbours_with_ground
end

-- Goes through the map and finds dead ends (tiles with 3 walls around them) and fills them in
-- does this recursivly until every tile has at least 2 ground neighbours
local function remove_all_dead_ends(map)
    local function fill_dead_end(x, y)
        local neighbours_with_ground = get_neighbours_with_ground(map, x, y)
        if #neighbours_with_ground == 1 then
            map[y][x] = false
            local neighbour = neighbours_with_ground[1]
            fill_dead_end(neighbour.x, neighbour.y)
        end
    end
    for y = 1, #map do
        for x = 1, #map[y] do
            fill_dead_end(x, y)
        end
    end
end

local function add_ores_at_dead_ends(map)
    for y = 1, #map do
        for x = 1, #map[y] do
            -- If it is a ground tile with only one ground neighbour it is a dead end
            local neighbours = get_neighbours_with_ground(map, x, y)
            if map[y][x] and #neighbours == 1 then
                local ore_letter = get_random_ore_letter()
                map[y][x] = ore_letter
                local n = neighbours[1]
                map[n.y][n.x] = ore_letter
            end
        end
    end
end

local map

-- Initializes the map which is saved in the variable map
local function create_map()
    -- A matrix with true if there is land and false if there is void
    map = initialize_grid(maze_width, maze_height)
    add_spawn_room(map)
    add_rooms(map, num_room_attempts, min_room_size, max_room_size)
    fill_with_mazes(map)
    connect_regions(map, extra_connection_attempts)
    map[1][maze_width] = true
    map[maze_height][1] = true
    add_ores_at_dead_ends(map)
    --remove_all_dead_ends(map)
end

-- Takes a filter_function(tile)->boolean
-- Returns a builder function which will return the value of the filter_function for the tile at those coordinates
local function builder_generator(filter_function, return_value_for_out_of_bounds)
    return_value_for_out_of_bounds = return_value_for_out_of_bounds or false
    return function(x, y)
        x = math.floor(x)
        y = math.floor(y)
        if map[y] == nil or map[y][x] == nil then
            -- Outside the map
            return return_value_for_out_of_bounds
        end
        return filter_function(map[y][x])
    end
end

--[[
    Uncomment below to run this file separatly and print result
random = math.random
create_map()
print_map(map)
]]
--[[
    Uncomment below to run in factorio
]]
Global.register_init(
    {},
    function(tbl)
        -- this is call on init event
        tbl.seed = RS.get_surface().map_gen_settings.seed
        tbl.random = game.create_random_generator(tbl.seed)
    end,
    function(tbl)
        -- this is called after on init and load event
        random = tbl.random
        random.re_seed(tbl.seed)
        create_map()
    end
)

-- Returns true if the position is ground, returns false if it's a wall
local factorio_map =
    builder_generator(
    function(tile)
        if tile == false then
            return false
        end
        return true
    end
)
-- Add all ores to factorio_map
for _, ore_data in pairs(ores) do
    local ore_shape =
        builder_generator(
        function(tile)
            return tile == ore_data.letter
        end
    )
    local ore = b.resource(ore_shape, ore_data.resource, ore_data.value)
    factorio_map = b.apply_entity(factorio_map, ore)
end

-- Translate the map so that players spawn in the spawn_room and so that the pattern will work
factorio_map2 = b.translate(factorio_map, -maze_width / 2 - 1, -maze_height / 2 - 1)
-- Apply pattern so the maze is repeted infinitly
factorio_map3 = b.single_pattern(factorio_map2, maze_width, maze_height)

local start_patch = b.rectangle(1, 1)
local start_iron_patch =
    b.resource(
    b.translate(start_patch, -1, -1),
    'iron-ore',
    function()
        return 15000
    end
)
local start_copper_patch =
    b.resource(
    b.translate(start_patch, 1, -1),
    'copper-ore',
    function()
        return 12000
    end
)
local start_stone_patch =
    b.resource(
    b.translate(start_patch, -1, 1),
    'stone',
    function()
        return 6000
    end
)
local start_coal_patch =
    b.resource(
    b.translate(start_patch, 1, 1),
    'coal',
    function()
        return 13500
    end
)

local start_resources = b.any({start_iron_patch, start_copper_patch, start_stone_patch, start_coal_patch})
local factorio_map4 = b.apply_entity(factorio_map3, start_resources)

-- Scale the map using the tile_scale variable
factorio_map = b.scale(factorio_map4, tile_scale, tile_scale)
return factorio_map
