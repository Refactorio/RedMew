local b = require 'map_gen.shared.builders'
local rad = math.rad

-- x and y must be even numbers else rail grid is misaligned.
local spawn_position = { x = 18, y = 18 }

local function is_not_water_tile(_, _, world)
    local gen_tile = world.surface.get_tile(world.x, world.y)
    return not gen_tile.collides_with('water_tile')
end

local width = 6 * 32
local height = 4 * 32
local l = math.sqrt(width^2 + height^2) - 40 * math.tan(height/width)
local station_length = 40

local station = b.any {
    b.rectangle(station_length, 18),
    b.translate(b.square_diamond(18), station_length / 2, 0), -- these just make it pretty
    b.translate(b.square_diamond(18), station_length / -2, 0) -- these just make it pretty
}

local rail_grid = b.add(
    b.subtract(b.rectangle(width, height), b.rotate(b.rectangle(l), rad(45))),
    b.subtract(b.rectangle(width, height), b.rectangle(width-6, height-6))
)

rail_grid = b.any{
    rail_grid,
    b.translate(b.rotate(station, rad(90)), -width/2, 0),
    b.translate(b.rotate(station, rad(90)), width/2, 0)
}

rail_grid = b.any{
    rail_grid,
    b.translate(rail_grid, width/2, height),
    b.translate(rail_grid, -width/2, height)
}

rail_grid = b.change_tile(rail_grid, true, 'landfill') -- MUST be landfill or the rail removal event doesn't work.
rail_grid = b.single_pattern_overlap(rail_grid, width, 2*height)

rail_grid = b.choose(is_not_water_tile, rail_grid, b.full_shape)
rail_grid= b.if_else(rail_grid, b.full_shape)

-- replace grass tiles with dirt so that the rail grid is more clear.
local tile_map = {
    ['grass-1'] = 'dirt-1',
    ['grass-2'] = 'dirt-2',
    ['grass-3'] = 'dirt-3',
    ['grass-4'] = 'dirt-4'
}
rail_grid = b.change_map_gen_tiles(rail_grid, tile_map)
rail_grid = b.translate(rail_grid, 1 - spawn_position.x, 1 - spawn_position.y)

return rail_grid
