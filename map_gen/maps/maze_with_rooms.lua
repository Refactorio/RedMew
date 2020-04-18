-- Height and width should always be odd numbers
local maze_width = 53
local maze_height = 53
-- room_sizes must always be odd
local min_room_size = 5
local max_room_size = 31
local spawn_room_size = 21
-- Number of rooms to try to place, if a room overlaps another one it will be skipped meaning this is the max
local num_room_attempts = 50
-- The number of extra connections to try to add after the map is already fully connected
-- set to 0 for no loops, higher numbers will make more loops
local extra_connection_attempts = 10
-- The number of factorio tiles per maze tile
local tile_scale = 10

local random
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
local function avg(a, b)
    return (a + b) / 2
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
local function add_rooms(map, num_room_attempts, min_room_size, max_room_size)
    -- room_size must be odd
    for attempt = 1, num_room_attempts do
        -- Generates a random odd number between min_room_size and max_room_size (inclusive both)
        local room_size = min_room_size + random(0, (max_room_size - min_room_size) / 2) * 2
        -- Generates a random odd top_left corner cordinate which would fit the room within the map
        local x = random(1, (#map[1] - room_size + 2) / 2) * 2 - 1
        local y = random(1, (#map - room_size + 2) / 2) * 2 - 1
        try_place_room(map, x, y, room_size)
    end
end

-- Adds a room with size spawn_room_size in the center.
-- If it happens to be an even coordinate the room must be shifted one step to be at an odd
local function add_spawn_room(map)
    local room_size = spawn_room_size
    local center_x = (maze_width + 1) / 2
    local center_y = (maze_height + 1) / 2
    local room_radius = (room_size - 1) / 2
    local x = center_x - room_radius
    local y = center_y - room_radius
    if x % 2 == 0 then
        x = x + 1
    end
    if y % 2 == 0 then
        y = y + 1
    end

    try_place_room(map, x, y, room_size)
end

-- Connects all different regions by making random walls between different regions into ground
local function connect_regions(map, extra_connection_attempts)
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
    for i = 1, extra_connection_attempts do
        local connector = connectors[random(#connectors)]
        local pos = connector.pos
        map[pos.y][pos.x] = true
    end
end

-- Goes through the map and finds dead ends (tiles with 3 walls around them) and fills them in
-- does this recursivly until every tile has at least 2 ground neighbours
local function remove_dead_ends(map)
    function get_neighbours_with_ground(x, y)
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
    function remove_dead_end(x, y)
        local neighbours_with_ground = get_neighbours_with_ground(x, y)
        if #neighbours_with_ground == 1 then
            map[y][x] = false
            local neighbour = neighbours_with_ground[1]
            remove_dead_end(neighbour.x, neighbour.y)
        end
    end
    for y = 1, #map do
        for x = 1, #map[y] do
            remove_dead_end(x, y)
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
    remove_dead_ends(map)
end

-- Returns true if the position is ground, returns false if it's a wall
local function has_ground_at(x, y)
    x = math.floor(x)
    y = math.floor(y)
    if map[y] == nil or map[y][x] == nil then
        -- Outside the map
        return false
    end
    if map[y][x] == false then
        return false
    end
    return true
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
local Global = require 'utils.global'
local RS = require 'map_gen.shared.redmew_surface'
local b = require 'map_gen.shared.builders'
local Event = require 'utils.event'

Global.register_init(
    {},
    function(tbl)
        -- this is call on init event
        tbl.seed = RS.get_surface().map_gen_settings.seed
    end,
    function(tbl)
        -- this is called after on init and load event
        random = game.create_random_generator(tbl.seed)
        create_map()
    end
)

-- Translate the map so that players spawn in the spawn_room
-- Scale the map using the tile_scale variable
return b.scale(b.translate(has_ground_at, -maze_width / 2, -maze_height / 2), tile_scale, tile_scale)
