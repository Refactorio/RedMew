local tile_types = {
	"concrete",
"deepwater",
"deepwater-green",
"dirt",
"dirt-dark",
"grass",
"grass-dry",
"grass-medium",
"hazard-concrete-left",
"hazard-concrete-right",
"lab-dark-1",
"lab-dark-2",
"out-of-map",
"red-desert",
"red-desert-dark",
"sand",
"sand-dark",
"stone-path",
"water",
"water-green"
}

local tile_width = 32
local tile_height = 32

local tile_data = {}

local abs_y = 1

for e,_ in ipairs(tile_types) do
	for y = 1, tile_width do
		row = {}
		for x = 1, tile_height do
			table.insert( row, e)
		end
--		abs_y = abs_y + 1
		table.insert(tile_data, row)
--		tile_data[abs_y] = row
	end
end

return {
height = tile_height * #tile_data,
width = tile_height,
data = tile_data
}
