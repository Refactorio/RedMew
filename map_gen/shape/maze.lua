require "map_gen.shared.chunk_utils"

local wall_thickness = 1
local cell_size = 3 --must be an uneven number


local wall_delta = math.floor((cell_size-wall_thickness)/2)
local chunk_size = 32

pixels = {}
cells = {}
function add_tile(x, y, width, height, add_cell)
    if add_cell then
        if cells[x] == nil then cells[x] = {} end
        cells[x][y] = 1
    end
    for xpos = x, x + width -1 do
        for ypos = y, y + height -1 do
            if pixels[xpos] == nil then pixels[xpos] = {} end
            pixels[xpos][ypos] = 1
        end
    end
end

global.max = 0
function render()
    for x,_ in pairs(pixels) do
                for y,_ in pairs(pixels[x]) do
            if y * 32 > global.max and y % 2 == 0 then
                global.max = y * 32
            end
            global.rects[x*32 .. "/" .. y*32] = 1
        end
    end
end

global.rnd_p = 1
function psd_rnd(l, h)
        while global.shuffle_pool[global.rnd_p] < l do
            global.rnd_p = global.rnd_p + 1
        end
        local res = global.shuffle_pool[global.rnd_p]
        global.rnd_p = global.rnd_p + 1
        return res
    end
    function shuffle(t)
      for i = 1, #t - 1 do
        local r = psd_rnd(i, #t)
         t[i], t[r] = t[r], t[i]
      end
end

-- builds a width-by-height grid of trues
function initialize_grid(w, h)
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
function avg(a, b)
  return (a + b) / 2
end


dirs = {
  {x = 0, y = -2}, -- north
  {x = 2, y = 0}, -- east
  {x = -2, y = 0}, -- west
  {x = 0, y = 2}, -- south
}

function make_maze(w, h)
  w = w or 16
  h = h or 16

  local map = initialize_grid(w*2+1, h*2+1)

  function walk(x, y)
    map[y][x] = false

    local d = { 1, 2, 3, 4 }
    shuffle(d)
    for i, dirnum in ipairs(d) do
      local xx = x + dirs[dirnum].x
      local yy = y + dirs[dirnum].y
      if map[yy] and map[yy][xx] then
        map[avg(y, yy)][avg(x, xx)] = false
        walk(xx, yy)
      end
    end
  end
  walk(global.walk_seed_w, global.walk_seed_h)

  local s = {}
  for i = 1, h*2+1 do
    for j = 1, w*2+1 do
      if map[i][j] then
    add_tile(i*cell_size,j*cell_size,cell_size,cell_size, true)
      end
    end
  end
  return table.concat(s)
end

local function reduce_walls()
    for x,_ in pairs(cells) do
        for y,_ in pairs(cells[x]) do
            if cells[x - cell_size] ~= nil and cells[x-cell_size][y] ~= 1 then
                add_tile(x-wall_delta, y, wall_delta, cell_size, false)
            end
                        if cells[x + cell_size] ~= nil and cells[x + cell_size][y] ~= 1 then
                            add_tile(x + cell_size, y,  wall_delta, cell_size, false)
                        end
            if cells[x] ~= nil and cells[x][y - cell_size] ~= 1 then
                add_tile(x - wall_delta, y - wall_delta, cell_size + 2 * wall_delta , wall_delta, false)
            end
            if cells[x] ~= nil and cells[x][y + cell_size] ~= 1 then
                add_tile(x - wall_delta, y + cell_size, cell_size + 2 * wall_delta, wall_delta, false)
            end
        end
    end
end
function init()
    if not global.walk_seed_w then global.walk_seed_w = math.random(1, 50)*2 end
    if not global.rects then global.rects = {} end
    if not global.walk_seed_h then global.walk_seed_h = math.random(1, 50)*2 end
    if not global.shuffle_pool then
        global.shuffle_pool = {}
        for i=1,20000 do
            global.shuffle_pool[i] = math.random(1, 4)
        end
    end
    make_maze(50, 50)
    reduce_walls()
    render()
end


first = true
function run_shape_module(event)
    if first then
        first = false
        init()
    end
  local pos = event.area.left_top
    if math.abs(pos.x) > 10000 or math.abs(pos.y) > 10000 or (global.rects[pos.x + global.max/2  .. "/" .. pos.y + global.max/2] == nil) then
            removeChunk(event)
    end
end
