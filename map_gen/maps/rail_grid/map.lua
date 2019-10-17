local b = require 'map_gen.shared.builders'
local rad = math.rad

-- x and y must be even numbers else rail grid is misaligned.
local spawn_position = {x = 20, y = 20}

local function is_not_water_tile(_, _, world)
    local gen_tile = world.surface.get_tile(world.x, world.y)
    return not gen_tile.collides_with('water-tile')
end

local station_length = 40
local station =
    b.any {
    b.rectangle(station_length, 18),
    b.translate(b.square_diamond(18), station_length / 2, 0), -- these just make it pretty
    b.translate(b.square_diamond(18), station_length / -2, 0) -- these just make it pretty
}

local grid_size = 224
local path =
    b.any {
    b.square_diamond(40),
    b.rectangle(grid_size, 6),
    b.rectangle(6, grid_size),
    b.circular_pattern(b.rotate(station, rad(90)), 4, grid_size / 3)
}

path = b.change_tile(path, true, 'landfill') -- MUST be landfill or the rail removal event doesn't work.
local grid = b.single_grid_pattern(path, grid_size, grid_size)

local no_water_grid = b.choose(is_not_water_tile, grid, b.full_shape)

local map = b.if_else(no_water_grid, b.full_shape)

-- replace grass tiles with dirt so that the rail grid is more clear.
local tile_map = {
    ['grass-1'] = 'dirt-1',
    ['grass-2'] = 'dirt-2',
    ['grass-3'] = 'dirt-3',
    ['grass-4'] = 'dirt-4'
}
map = b.change_map_gen_tiles(map, tile_map)

map = b.translate(map, 1 - spawn_position.x, 1 - spawn_position.y)

return map
