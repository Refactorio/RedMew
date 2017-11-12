local tile_types = {
	"concrete",
	"deepwater",
	"deepwater-green",
	"dirt",
	"dirt-dark",
	"grass",
	"grass-medium",
	"grass-dry",
	"hazard-concrete-left",
	"hazard-concrete-right",
	"lab-dark-1",
	"lab-dark-2",
	"red-desert",
	"red-desert-dark",
	"sand",
	"sand-dark",
	"stone-path",
	"water",
	"water-green",
	"out-of-map",
}
local cols = 5
local rows = 20 / cols

local tile_width = 64
local tile_height = 64

local tile_data = {}

local abs_y = 0
local rel_x = 0
local abs_col = 0
local block = 0

for _,e in pairs(tile_types) do
	block = _  - 1

	abs_row = math.floor(block / cols)
	abs_col = block % cols

	rel_x = tile_width * (abs_col)
	rel_y = tile_height * (abs_row)

	for y = 1, tile_height do
		if tile_data[rel_y + y] == nil then
			tile_data[rel_y + y] = {}
		end
		for x = 1, tile_width do
			tile_data[rel_y + y][rel_x + x] = e
		end
	end

end

return {
	height = tile_height * rows,
	width = tile_width * cols,
	data = tile_data
}
