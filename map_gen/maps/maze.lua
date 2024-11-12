local Event = require 'utils.event'
local RS = require 'map_gen.shared.redmew_surface'
local Global = require 'utils.global'
local math = require 'utils.math'
local table = require 'utils.table'

local insert = table.insert
local shuffle = table.shuffle_table
local math_abs = math.abs
local math_floor = math.floor
local math_random = math.random

local MAZE_SIZE = 50
local WALL_THICKNESS = 1
local CELL_SIZE = 3 -- must be an odd number
local WALL_DELTA = math_floor((CELL_SIZE - WALL_THICKNESS) / 2)
local DIRECTIONS = {
    { x = 0, y = -2 }, -- north
    { x = 2, y = 0 }, -- east
    { x = -2, y = 0 }, -- west
    { x = 0, y = 2 }, -- south
}

local pixels = {}
local cells = {}
local primitives = { max = 0, walk_seed_w = 0, walk_seed_h = 0 }
local rectangles = {}

Global.register(
    {
        primitives = primitives,
        rectangles = rectangles
    },
    function(tbl)
        primitives = tbl.primitives
        rectangles = tbl.rectangles
    end
)

local function add_tile(x, y, width, height, add_cell)
    if add_cell then
        if cells[x] == nil then
        cells[x] = {}
        end
        cells[x][y] = 1
    end
    for x_pos = x, x + width - 1 do
        for y_pos = y, y + height - 1 do
        if pixels[x_pos] == nil then
            pixels[x_pos] = {}
        end
        pixels[x_pos][y_pos] = 1
        end
    end
end

local function render()
    for x, _ in pairs(pixels) do
        for y, _ in pairs(pixels[x]) do
        if y * 32 > primitives.max and y % 2 == 0 then
            primitives.max = y * 32
        end
        rectangles[x * 32 .. '/' .. y * 32] = 1
        end
    end
end

-- builds a width-by-height grid of trues
local function initialize_grid(w, h)
    local a = {}
    for i = 1, h do
        insert(a, {})
        for j = 1, w do
        insert(a[i], true)
        end
    end
    return a
end

-- average of a and b
local function avg(a, b)
    return (a + b) / 2
end

local function make_maze(w, h)
    local map = initialize_grid(w * 2 + 1, h * 2 + 1)

    local walk
    walk = function(x, y)
        map[y][x] = false

        local d = { 1, 2, 3, 4 }
        shuffle(d)
        for i, dir_num in pairs(d) do
        local xx = x + DIRECTIONS[dir_num].x
        local yy = y + DIRECTIONS[dir_num].y
        if map[yy] and map[yy][xx] then
            map[avg(y, yy)][avg(x, xx)] = false
            walk(xx, yy)
        end
        end
    end
    walk(primitives.walk_seed_w, primitives.walk_seed_h)

    for i = 1, h * 2 + 1 do
        for j = 1, w * 2 + 1 do
        if map[i][j] then
            add_tile(i * CELL_SIZE, j * CELL_SIZE, CELL_SIZE, CELL_SIZE, true)
        end
        end
    end
end

local function reduce_walls()
    for x, _ in pairs(cells) do
        for y, _ in pairs(cells[x]) do
        if cells[x - CELL_SIZE] ~= nil and cells[x - CELL_SIZE][y] ~= 1 then
            add_tile(x - WALL_DELTA, y, WALL_DELTA, CELL_SIZE, false)
        end
        if cells[x + CELL_SIZE] ~= nil and cells[x + CELL_SIZE][y] ~= 1 then
            add_tile(x + CELL_SIZE, y, WALL_DELTA, CELL_SIZE, false)
        end
        if cells[x] ~= nil and cells[x][y - CELL_SIZE] ~= 1 then
            add_tile(x - WALL_DELTA, y - WALL_DELTA, CELL_SIZE + 2 * WALL_DELTA, WALL_DELTA, false)
        end
        if cells[x] ~= nil and cells[x][y + CELL_SIZE] ~= 1 then
            add_tile(x - WALL_DELTA, y + CELL_SIZE, CELL_SIZE + 2 * WALL_DELTA, WALL_DELTA, false)
        end
        end
    end
end

local function remove_chunk(event)
    local surface, area = event.surface, event.area
    local tiles = {}
    for x = area.left_top.x, area.right_bottom.x - 1 do
        for y = area.left_top.y, area.right_bottom.y - 1 do
        insert(tiles, { name = 'out-of-map', position = { x, y } })
        end
    end
    surface.set_tiles(tiles)
end

Event.on_init(function()
    primitives.walk_seed_w = math_random(1, MAZE_SIZE) * 2
    primitives.walk_seed_h = math_random(1, MAZE_SIZE) * 2
    make_maze(MAZE_SIZE, MAZE_SIZE)
    reduce_walls()
    render()
end)

Event.add(defines.events.on_chunk_generated, function(event)
    if event.surface == RS.get_surface() then
        local pos = event.area.left_top
        if math_abs(pos.x) > 10000 or math_abs(pos.y) > 10000 or
            (rectangles[pos.x + primitives.max / 2 .. '/' .. pos.y + primitives.max / 2] == nil) then
        remove_chunk(event)
        end
    end
end)
