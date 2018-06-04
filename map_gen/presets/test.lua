local b = require 'map_gen.shared.builders'

local tile_map = {
    [1] = false,
    [2] = true,
    [3] = 'concrete',
    [4] = 'deepwater-green',
    [5] = 'deepwater',
    [6] = 'dirt-1',
    [7] = 'dirt-2',
    [8] = 'dirt-3',
    [9] = 'dirt-4',
    [10] = 'dirt-5',
    [11] = 'dirt-6',
    [12] = 'dirt-7',
    [13] = 'dry-dirt',
    [14] = 'grass-1',
    [15] = 'grass-2',
    [16] = 'grass-3',
    [17] = 'grass-4',
    [18] = 'hazard-concrete-left',
    [19] = 'hazard-concrete-right',
    [20] = 'lab-dark-1',
    [21] = 'lab-dark-2',
    [22] = 'lab-white',
    [23] = 'out-of-map',
    [24] = 'red-desert-0',
    [25] = 'red-desert-1',
    [26] = 'red-desert-2',
    [27] = 'red-desert-3',
    [28] = 'sand-1',
    [29] = 'sand-2',
    [30] = 'sand-3',
    [31] = 'stone-path',
    [32] = 'water-green',
    [33] = 'water'
}

local data = {}

for count = 1, 33 do
    local r = count % 10

    local row
    if r == 1 then
        row = {}
        table.insert(data, row)
    else
        row = data[#data]
    end

    row[#row + 1] = tile_map[count]
end

local tiles = {}
tiles.width = 10
tiles.height = 4
tiles.data = data

local pic = b.picture(tiles)

return b.scale(pic, 4)
