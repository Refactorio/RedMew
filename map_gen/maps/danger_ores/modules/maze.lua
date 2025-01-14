local Event = require 'utils.event'
local Generate = require 'map_gen.shared.generate'
local Global = require 'utils.global'
local RS = require 'map_gen.shared.redmew_surface'
local math = require 'utils.math'
local table = require 'utils.table'

local insert = table.insert
local shuffle = table.shuffle_table
local math_max = math.max
local math_floor = math.floor
local math_random = math.random

return function(config)
  local MAZE_SIZE = config.size
  local WALL_THICKNESS = config.wall_thickness
  local CELL_SIZE = config.cell_size
  local WALL_DELTA = math_floor((CELL_SIZE - WALL_THICKNESS) / 2)
  local DIRECTIONS = {
    { x =  0, y = -2 }, -- north
    { x =  2, y =  0 }, -- east
    { x = -2, y =  0 }, -- west
    { x =  0, y =  2 }, -- south
  }

  local pixels = {}
  local cells = {}
  local maze_walls = {}
  local primitives = {
    max = 0,
    walk_seed_w = 0,
    walk_seed_h = 0,
  }

  Global.register({
      maze_walls = maze_walls,
      primitives = primitives,
    },
    function(tbl)
      maze_walls = tbl.maze_walls
      primitives = tbl.primitives
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
    local y_max = 0
    for x, _ in pairs(pixels) do
      for y, _ in pairs(pixels[x]) do
        if y * 32 > primitives.max and y % 2 == 0 then
          y_max = math_max(y_max, y)
        end
      end
    end
    primitives.max = y_max * 32

    for x = 1, y_max do
      for y = 1, WALL_DELTA do
        if not pixels[x] then
          pixels[x] = {}
        end
        pixels[x][y] = 1
      end
    end
    for x = 1, WALL_DELTA do
      for y = 1, y_max do
        if not pixels[x] then
          pixels[x] = {}
        end
        pixels[x][y] = 1
      end
    end

    for x = 1, y_max do
      for y = 1, y_max do
        if not (pixels[x] and pixels[x][y]) then
          maze_walls[x * 32 .. '/' .. y * 32] = true
        end
      end
    end
  end

  -- builds a width-by-height grid
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

  local function is_map(x, y)
    return cells[x] and cells[x][y] == 1
  end

  local function is_wall(x, y)
    return not is_map(x, y)
  end

  local function reduce_walls()
    for x, _ in pairs(cells) do
      for y, _ in pairs(cells[x]) do
        -- Left
        if is_wall(x - CELL_SIZE, y) then
          add_tile(x - WALL_DELTA, y, WALL_DELTA, CELL_SIZE, false)
        end
        -- Right
        if is_wall(x + CELL_SIZE, y) then
          add_tile(x + CELL_SIZE, y, WALL_DELTA, CELL_SIZE, false)
        end
        -- Above
        if is_wall(x, y - CELL_SIZE) then
          add_tile(x - WALL_DELTA, y - WALL_DELTA, CELL_SIZE + 2 * WALL_DELTA, WALL_DELTA, false)
        end
        -- Below
        if is_wall(x, y + CELL_SIZE) then
          add_tile(x - WALL_DELTA, y + CELL_SIZE, CELL_SIZE + 2 * WALL_DELTA, WALL_DELTA, false)
        end
      end
    end
  end

  local function remove_chunk(surface, area)
    local tiles = {}
    for x = area.left_top.x, area.right_bottom.x - 1 do
      for y = area.left_top.y, area.right_bottom.y - 1 do
        insert(tiles, { name = 'out-of-map', position = { x = x, y = y } })
      end
    end
    surface.set_tiles(tiles)
  end

  local set_wall_tiles = function(surface, area)
    if not config.enabled then
      return
    end

    local pos = area.left_top
    if maze_walls[pos.x + primitives.max / 2 .. '/' .. pos.y + primitives.max / 2] then
      remove_chunk(surface, area)
      return true
    end
    return
  end

  Event.on_init(function()
    if not config.enabled then
      return
    end

    primitives.walk_seed_w = math_random(1, MAZE_SIZE) * 2
    primitives.walk_seed_h = math_random(1, MAZE_SIZE) * 2
    make_maze(MAZE_SIZE, MAZE_SIZE)
    reduce_walls()
    render()
  end)

  Event.add(Generate.events.on_chunk_generated, function(event)
    local surface, area = event.surface, event.area
    if surface ~= RS.get_surface() then
      return
    end
    -- Make maze walls
    set_wall_tiles(surface, area)
  end)
end