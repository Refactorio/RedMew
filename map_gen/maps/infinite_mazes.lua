local Event = require 'utils.event'
local RS = require 'map_gen.shared.redmew_surface'
local Global = require 'utils.global'
--Author: Hexicube
--The size of each individual maze, in cells.
local maze_width = 17
local maze_height = 17

--The size of each cell within a maze, in tiles. This includes the border.
--This is also the thickness of passages between mazes.
local maze_tile_size = 80
--The thickness of cell borders (walls), in tiles.
local maze_tile_border = 2
--These two values are specifically chosen to only just allow train loops.
--If tile size is reduced or border size is increased, players will be forced to use 4-way crossings instead.

--Number of ore cells per maze, for each type.
local iron_ore_count = 8
local copper_ore_count = 6
local coal_ore_count = 4
local stone_ore_count = 2
local uranium_ore_count = 1

local resource_density_factor = 500

--Warning: Do not exceed the total number of cells in the maze, or it will break!

--DO NOT TOUCH BELOW THIS LINE--
local _ -- garbage collection var
local bor = bit32.bor
local bxor = bit32.bxor
local band = bit32.band
local rshift = bit32.rshift

local global_ore_data = {}
local global_maze_data = {}
local primitives = {
    maze_seed = 0,
}

Global.register(
    {
        primitives = primitives,
        global_ore_data = global_ore_data,
    },
    function(tbl)
        primitives = tbl.primitives
        global_ore_data = tbl.global_ore_data
    end
)

local function get_random_maze_val(cur_seed)
    local new_seed = bor(cur_seed + 0x9E3779B9, 0)
    local return_val = bor(new_seed * 0xBF58476D, 0)
    return_val = bor(return_val * 0x94D049BB, 0)
    return new_seed, bor(return_val, 0)
end

local last_maze_x, last_maze_y, last_maze
local function get_maze(x, y, seed, width, height)
    if last_maze and last_maze_x == x and last_maze_y == y then
        return last_maze
    end

    if not global_maze_data[x] then
        global_maze_data[x] = {}
    end
    if global_maze_data[x][y] then
        last_maze = global_maze_data[x][y]
        last_maze_x = x
        last_maze_y = y
        return last_maze
    end

    local maze_data = {}
    local grid = {}
    for tx = 1, width do
        maze_data[tx] = {}
        grid[tx] = {}
        for ty = 1, height do
            maze_data[tx][ty] = 15
            grid[tx][ty] = true
        end
    end

    local maze_seed = bxor(bit32.lshift(x, 16) + band(y, 65535), seed)
    local value

    local queue = {}
    maze_seed, value = get_random_maze_val(maze_seed)
    local pos = {0, 0}
    pos[1] = value % width + 1
    value = rshift(value, 16)
    pos[2] = value % height + 1

    queue[#queue + 1] = {pos[1], pos[2], pos[1] - 1, pos[2]}
    queue[#queue + 1] = {pos[1], pos[2], pos[1] + 1, pos[2]}
    queue[#queue + 1] = {pos[1], pos[2], pos[1], pos[2] - 1}
    queue[#queue + 1] = {pos[1], pos[2], pos[1], pos[2] + 1}

    while #queue > 0 do
        maze_seed, value = get_random_maze_val(maze_seed)
        local connection = table.remove(queue, value % #queue + 1)
        local sx, sy = connection[1], connection[2]
        local tx, ty = connection[3], connection[4]
        if tx > 0 and ty > 0 and tx <= width and ty <= height and grid[tx][ty] then
            local dx, dy = sx - tx, sy - ty
            local mod_s, mod_t = 3, 3
            if dy == 1 then
                mod_s = 1
            elseif dy == -1 then
                mod_t = 1
            elseif dx == 1 then
                mod_s = 2
            else
                mod_t = 2
            end
            maze_data[sx][sy] = band(maze_data[sx][sy], mod_s)
            maze_data[tx][ty] = band(maze_data[tx][ty], mod_t)
            grid[sx][sy] = false
            grid[tx][ty] = false

            queue[#queue + 1] = {tx, ty, tx - 1, ty}
            queue[#queue + 1] = {tx, ty, tx + 1, ty}
            queue[#queue + 1] = {tx, ty, tx, ty - 1}
            queue[#queue + 1] = {tx, ty, tx, ty + 1}
        end
    end

    maze_seed, value = get_random_maze_val(maze_seed)
    maze_data[value % width + 1][1] = band(maze_data[value % width + 1][1], 1)
    value = rshift(value, 16)
    maze_data[1][value % height + 1] = band(maze_data[1][value % height + 1], 2)

    _, value = get_random_maze_val(maze_seed)
    maze_data[width + 1] = {0, 0}
    maze_data[width + 1][1] = value % width + 1
    value = rshift(value, 16)
    maze_data[width + 1][2] = value % height + 1

    global_maze_data[x][y] = maze_data
    last_maze = maze_data
    last_maze_x = x
    last_maze_y = y
    return maze_data
end

local last_maze_ore_x, last_maze_ore_y, last_maze_ore
local function get_maze_ore(x, y, seed, width, height)
    if last_maze_ore and last_maze_ore_x == x and last_maze_ore_y == y then
        return last_maze_ore
    end

    if not global_ore_data[x] then
        global_ore_data[x] = {}
    end
    if global_ore_data[x][y] then
        last_maze_ore = global_ore_data[x][y]
        last_maze_ore_x = x
        last_maze_ore_y = y
        return last_maze_ore
    end

    local coord_list = {}
    local maze_data = {}
    for tx = 1, width do
        maze_data[tx] = {}
        for ty = 1, height do
            maze_data[tx][ty] = nil
            coord_list[#coord_list + 1] = {tx, ty}
        end
    end

    local maze_seed = bxor(bit32.lshift(x, 16) + band(y, 65535), seed)
    local value

    for _ = 1, iron_ore_count do
        maze_seed, value = get_random_maze_val(maze_seed)
        local pos = table.remove(coord_list, value % #coord_list + 1)
        maze_data[pos[1]][pos[2]] = 'iron-ore'
    end
    for _ = 1, copper_ore_count do
        maze_seed, value = get_random_maze_val(maze_seed)
        local pos = table.remove(coord_list, value % #coord_list + 1)
        maze_data[pos[1]][pos[2]] = 'copper-ore'
    end
    for _ = 1, coal_ore_count do
        maze_seed, value = get_random_maze_val(maze_seed)
        local pos = table.remove(coord_list, value % #coord_list + 1)
        maze_data[pos[1]][pos[2]] = 'coal'
    end
    for _ = 1, stone_ore_count do
        maze_seed, value = get_random_maze_val(maze_seed)
        local pos = table.remove(coord_list, value % #coord_list + 1)
        maze_data[pos[1]][pos[2]] = 'stone'
    end
    for _ = 1, uranium_ore_count do
        maze_seed, value = get_random_maze_val(maze_seed)
        local pos = table.remove(coord_list, value % #coord_list + 1)
        maze_data[pos[1]][pos[2]] = 'uranium-ore'
    end

    global_ore_data[x][y] = maze_data
    last_maze_ore = maze_data
    last_maze_ore_x = x
    last_maze_ore_y = y
    return maze_data
end

local function global_to_maze_pos(x, y)
    --Ensures we start in the middle of a tile.
    x = x + maze_tile_size / 2
    y = y + maze_tile_size / 2

    local maze_width_raw = (maze_width + 1) * maze_tile_size
    local maze_height_raw = (maze_height + 1) * maze_tile_size

    local global_maze_x = math.floor(x / maze_width_raw)
    local global_maze_y = math.floor(y / maze_height_raw)
    x = x - global_maze_x * maze_width_raw
    y = y - global_maze_y * maze_height_raw

    local local_maze_x = math.floor(x / maze_tile_size)
    local local_maze_y = math.floor(y / maze_tile_size)
    x = x - local_maze_x * maze_tile_size
    y = y - local_maze_y * maze_tile_size

    return global_maze_x, global_maze_y, local_maze_x, local_maze_y, x, y
end

local function handle_maze_tile(x, y, _, seed)
    local orig_x, orig_y = x, y
    local global_maze_x, global_maze_y, local_maze_x, local_maze_y
    global_maze_x, global_maze_y, local_maze_x, local_maze_y, x, y = global_to_maze_pos(x, y)

    local maze_data = get_maze(global_maze_x, global_maze_y, seed, maze_width, maze_height)
    local maze_value = 0
    if local_maze_x == 0 or local_maze_y == 0 then
        if local_maze_x == 0 then
            if local_maze_y ~= 0 then
                if maze_data[maze_width + 1][1] ~= local_maze_y then
                    maze_value = 1
                end
            end
        else
            if maze_data[maze_width + 1][2] ~= local_maze_x then
                maze_value = 2
            end
        end
    else
        maze_value = maze_data[local_maze_x][local_maze_y]
    end

    if x < maze_tile_border and y < maze_tile_border then
        return {name = 'out-of-map', position = {orig_x, orig_y}}
    end
    if x < maze_tile_border and bit32.btest(maze_value, 1) then
        return {name = 'out-of-map', position = {orig_x, orig_y}}
    end
    if y < maze_tile_border and bit32.btest(maze_value, 2) then
        return {name = 'out-of-map', position = {orig_x, orig_y}}
    end
    return nil
end

local function handle_maze_tile_ore(x, y, surf, seed)
    local orig_x, orig_y = x, y
    local spawn_distance_1k = math.sqrt(x * x + y * y) / 1000
    local global_maze_x, global_maze_y, local_maze_x, local_maze_y
    global_maze_x, global_maze_y, local_maze_x, local_maze_y, x, y = global_to_maze_pos(x, y)

    if x < maze_tile_border or y < maze_tile_border then
        return
    end

    local ore_name = nil
    if local_maze_x == 0 or local_maze_y == 0 then
        if global_maze_x == 0 and global_maze_y == 0 then
            if local_maze_x == 1 and local_maze_y == 0 then
                ore_name = 'iron-ore'
            end
            if local_maze_x == 0 and local_maze_y == 1 then
                ore_name = 'stone'
            end
        elseif global_maze_x == -1 and global_maze_y == 0 and local_maze_x == maze_width and local_maze_y == 0 then
            ore_name = 'copper-ore'
        elseif global_maze_x == 0 and global_maze_y == -1 and local_maze_x == 0 and local_maze_y == maze_height then
            ore_name = 'coal'
        end
    else
        local ore_data = get_maze_ore(global_maze_x, global_maze_y, seed, maze_width, maze_height)
        ore_name = ore_data[local_maze_x][local_maze_y]
    end

    if ore_name then
        if surf.can_place_entity {name = ore_name, position = {orig_x, orig_y}} then
            local dist = spawn_distance_1k
            local resource_amount_max = math.floor(resource_density_factor * (dist * dist + 1))
            local dist_x = maze_tile_size - x - 1
            if (x - maze_tile_border) < dist_x then
                dist_x = (x - maze_tile_border)
            end
            local dist_y = maze_tile_size - y - 1
            if (y - maze_tile_border) < dist_y then
                dist_y = (y - maze_tile_border)
            end

            dist = dist_x
            if dist_y < dist then
                dist = dist_y
            end
            dist = dist + 1

            local resource_amount = resource_amount_max * dist / maze_tile_size * 2
            if resource_amount > resource_amount_max / 2 then
                surf.create_entity {name = ore_name, position = {orig_x, orig_y}, amount = resource_amount}
            end
        end
    end
end

local function on_chunk_generated_ore(event)
    local entities = event.surface.find_entities(event.area)
    for _, entity in pairs(entities) do
        if entity.type == 'resource' and entity.name ~= 'crude-oil' then
            entity.destroy()
        end
    end

    local tx, ty = event.area.left_top.x, event.area.left_top.y
    local ex, ey = event.area.right_bottom.x, event.area.right_bottom.y
    local surface = event.surface

    for x = tx, ex do
        for y = ty, ey do
            handle_maze_tile_ore(x, y, surface, primitives.maze_seed)
        end
    end
end

Event.on_init(
    function()
        primitives.maze_seed = math.random(0, 65536 * 65536 - 1)
    end
)

Event.add(
    defines.events.on_chunk_generated,
    function(event)
        if event.surface ~= RS.get_surface() then
            return
        end

        local tiles = {}
        local tx, ty = event.area.left_top.x, event.area.left_top.y
        local ex, ey = event.area.right_bottom.x, event.area.right_bottom.y
        local surface = event.surface

        for x = tx, ex do
            for y = ty, ey do
                local new_tile = handle_maze_tile(x, y, surface, primitives.maze_seed)
                if new_tile then
                    table.insert(tiles, new_tile)
                end
            end
        end
        surface.set_tiles(tiles, true)

        on_chunk_generated_ore(event)
    end
)
