local wall_thickness = 1
local cell_size = 1 --must be an uneven number


local wall_delta = math.floor((cell_size-wall_thickness)/2)
local chunk_size = 32

rects = {}
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

local max = 0
function render()        
	for x,_ in pairs(pixels) do
                for y,_ in pairs(pixels[x]) do
			if y * 32 > max and y % 2 == 0 then
				max = y * 32
			end
			rects[x*32 .. "/" .. y*32] = 1
		end
	end
end

  
function shuffle(t)
  for i = 1, #t - 1 do
    local r = math.random(i, #t)
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
 
  walk(math.random(1, w)*2, math.random(1, h)*2)
 
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
	game.print(game.tick)
--	math.randomseed( 78579837297 )
	make_maze(40, 40)
	reduce_walls()
	render()
	game.print(max)
end
first = true
function gen(event)
	if first then
		first = false
		init()
	end
        local pos = event.area.left_top
	if (rects[pos.x + max/2  .. "/" .. pos.y + max/2] == nil) then
			removeChunk(event)
	end
end

