local b = require 'map_gen.shared.builders'
local rad = math.rad

local ore_density_rail = b.euclidean_value(-150, 0.35)
local ore_density_block = b.exponential_value(-550, 0.07, 1.45)

local rail_grid
do
    local width = 6 * 32
    local height = 4 * 32
    local station_length = 40
    local spawn_position = { x = 18, y = 18 }
    local l = math.sqrt(width ^ 2 + height ^ 2) - 32 * math.tan(height / width)

    local station = b.any {
        b.rectangle(station_length, 14),
        b.translate(b.square_diamond(14), station_length / 2, 0), -- these just make it pretty
        b.translate(b.square_diamond(14), station_length / -2, 0), -- these just make it pretty
    }

    rail_grid = b.add(
        b.subtract(b.rectangle(width, height), b.rotate(b.rectangle(l), rad(45))),
        b.subtract(b.rectangle(width, height), b.rectangle(width - 6, height - 6))
    )

    rail_grid = b.any {
        rail_grid,
        b.translate(b.rotate(station, rad(90)), -width / 2, 0),
        b.translate(b.rotate(station, rad(90)), width / 2, 0),
    }

    rail_grid = b.any {
        rail_grid,
        b.translate(rail_grid, width / 2, height),
        b.translate(rail_grid, -width / 2, height),
    }

    rail_grid = b.single_pattern_overlap(rail_grid, width, 2 * height)
    rail_grid = b.translate(rail_grid, 1 - spawn_position.x, 1 - spawn_position.y)
    rail_grid = b.rotate(rail_grid, rad(90)) -- makes it look like playing cards rather than bricks
end

return {
    {
        name = 'coal',
        tiles = { 'landfill' },
        start = 1,
        weight = 1,
        ratios = {
            { resource = b.resource(rail_grid, 'coal', ore_density_rail), weight = 1 },
            { resource = b.resource(rail_grid, 'stone', ore_density_rail), weight = 1 },
        },
    },
    {
        name = 'iron-ore',
        tiles = { 'nuclear-ground' },
        start = 1,
        weight = 1,
        ratios = {
            { resource = b.resource(b.invert(rail_grid), 'iron-ore', ore_density_block), weight = 9 },
            { resource = b.resource(b.invert(rail_grid), 'copper-ore', ore_density_block), weight = 7 },
            { resource = b.resource(b.invert(rail_grid), 'coal', ore_density_block), weight = 4 },
            { resource = b.resource(b.invert(rail_grid), 'stone', ore_density_block), weight = 1 },
        },
    },
}
