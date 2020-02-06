local Event = require 'utils.event'
local RS = require 'map_gen.shared.redmew_surface'
local Global = require 'utils.global'

local wall_thickness = 1
local cell_size = 3 --must be an uneven number
local wall_delta = math.floor((cell_size - wall_thickness) / 2)

local pixels = {}
local cells = {}

local primitives = {
    max = 0,
    rnd_p = 1,
    walk_seed_w = 0,
    walk_seed_h = 0
}
local rects = {}
local shuffle_pool = {}

Global.register(
    {
        primitives = primitives,
        rects = rects,
        shuffle_pool = shuffle_pool
    },
    function(tbl)
        primitives = tbl.primitives
        rects = tbl.rects
    end
)

local function add_tile(x, y, width, height, add_cell)
    if add_cell then
        if cells[x] == nil then
            cells[x] = {}
        end
        cells[x][y] = 1
    end
    for xpos = x, x + width - 1 do
        for ypos = y, y + height - 1 do
            if pixels[xpos] == nil then
                pixels[xpos] = {}
            end
            pixels[xpos][ypos] = 1
        end
    end
end

primitives.max = 0
local function render()
    for x, _ in pairs(pixels) do
        for y, _ in pairs(pixels[x]) do
            if y * 32 > primitives.max and y % 2 == 0 then
                primitives.max = y * 32
            end
            rects[x * 32 .. '/' .. y * 32] = 1
        end
    end
end

primitives.rnd_p = 1
local function psd_rnd(l)
    while shuffle_pool[primitives.rnd_p] < l do
        primitives.rnd_p = primitives.rnd_p + 1
    end
    local res = shuffle_pool[primitives.rnd_p]
    primitives.rnd_p = primitives.rnd_p + 1
    return res
end

local function shuffle(t)
    for i = 1, #t - 1 do
        local r = psd_rnd(i, #t)
        t[i], t[r] = t[r], t[i]
    end
end

-- builds a width-by-height grid of trues
local function initialize_grid(w, h)
    local a = {}
    for i = 1, h do
        table.insert(a, {})
        for j = 1, w do
            table.insert(a[i], true)
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

local function make_maze(w, h)
    local map = initialize_grid(w * 2 + 1, h * 2 + 1)

    local walk
    walk = function(x, y)
        map[y][x] = false

        local d = {1, 2, 3, 4}
        shuffle(d)
        for i, dirnum in pairs(d) do
            local xx = x + dirs[dirnum].x
            local yy = y + dirs[dirnum].y
            if map[yy] and map[yy][xx] then
                map[avg(y, yy)][avg(x, xx)] = false
                walk(xx, yy)
            end
        end
    end
    walk(primitives.walk_seed_w, primitives.walk_seed_h)

    local s = {}
    for i = 1, h * 2 + 1 do
        for j = 1, w * 2 + 1 do
            if map[i][j] then
                add_tile(i * cell_size, j * cell_size, cell_size, cell_size, true)
            end
        end
    end
    return table.concat(s)
end

local function reduce_walls()
    for x, _ in pairs(cells) do
        for y, _ in pairs(cells[x]) do
            if cells[x - cell_size] ~= nil and cells[x - cell_size][y] ~= 1 then
                add_tile(x - wall_delta, y, wall_delta, cell_size, false)
            end
            if cells[x + cell_size] ~= nil and cells[x + cell_size][y] ~= 1 then
                add_tile(x + cell_size, y, wall_delta, cell_size, false)
            end
            if cells[x] ~= nil and cells[x][y - cell_size] ~= 1 then
                add_tile(x - wall_delta, y - wall_delta, cell_size + 2 * wall_delta, wall_delta, false)
            end
            if cells[x] ~= nil and cells[x][y + cell_size] ~= 1 then
                add_tile(x - wall_delta, y + cell_size, cell_size + 2 * wall_delta, wall_delta, false)
            end
        end
    end
end

local function remove_chunk(event)
    local surface = event.surface
    local tiles = {}
    for x = event.area.left_top.x, event.area.right_bottom.x do
        for y = event.area.left_top.y, event.area.right_bottom.y do
            table.insert(tiles, {name = 'out-of-map', position = {x, y}})
        end
    end
    surface.set_tiles(tiles)
end

Event.on_init(
    function()
        primitives.walk_seed_w = math.random(1, 50) * 2
        primitives.walk_seed_h = math.random(1, 50) * 2
        for i = 1, 20000 do
            shuffle_pool[i] = math.random(1, 4)
        end
        make_maze(50, 50)
        reduce_walls()
        render()
    end
)

Event.add(
    defines.events.on_chunk_generated,
    function(event)
        if event.surface == RS.get_surface() then
            local pos = event.area.left_top
            if
                math.abs(pos.x) > 10000 or math.abs(pos.y) > 10000 or
                    (rects[pos.x + primitives.max / 2 .. '/' .. pos.y + primitives.max / 2] == nil)
             then
                remove_chunk(event)
            end
        end
    end
)
