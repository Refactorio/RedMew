-- Dependencies
local b = require 'map_gen.shared.builders'
local Random = require 'map_gen.shared.random'
local table = require 'utils.table'
local Event = require 'utils.event'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

-- Localized functions
local insert = table.insert

-- Local vars
local ore_seed1 = 9000
local ore_seed2 = ore_seed1 * 2

-- Setup surface and map settings
RS.set_map_gen_settings(
    {
        MGSP.ore_oil_none,
        MGSP.cliff_none,
        MGSP.grass_only,
        MGSP.enable_water
    }
)

-- Overwrite default hydra config
local hail_hydra = global.config.hail_hydra
hail_hydra.enabled = true
hail_hydra.hydras = {
    -- spitters
    ['medium-spitter'] = {['small-spitter'] = 0.2},
    ['big-spitter'] = {['medium-spitter'] = 0.2},
    ['behemoth-spitter'] = {['big-spitter'] = 0.4},
    -- biters
    ['medium-biter'] = {['small-biter'] = 1.2},
    ['big-biter'] = {['medium-biter'] = 1.2},
    ['behemoth-biter'] = {['big-biter'] = 1.2},
    -- worms
    ['small-worm-turret'] = {['small-biter'] = 2.5},
    ['medium-worm-turret'] = {['small-biter'] = 2.5, ['medium-biter'] = 0.6},
    ['big-worm-turret'] = {['small-biter'] = 3.8, ['medium-biter'] = 1.3, ['big-biter'] = 1.1}
}

-- Create the Sierpinski carpet shape
local function grid(x, y)
    return not (x % 3 < 2 or y % 3 < 2)
end

grid = b.translate(grid, 2, 2)
local sierpinski = grid

for i = 1, 10, 1 do
    sierpinski =
        b.any {
        sierpinski,
        b.scale(grid, 3 ^ i, 3 ^ i)
    }
end

local function quadrant(x, y)
    return not (x < 0 or y > 0)
end

sierpinski = b.invert(sierpinski)
sierpinski = b.choose(quadrant, sierpinski, b.empty_shape) -- Restricts the Sierpinski pattern to one quadrant of the map co-ordinate system. Comment line to have whole map
sierpinski = b.scale(sierpinski, 10, 10) -- Scale it up so it's playable

-- Create a grid of tiles to make it look pretty. The sierpinski shape will be used as a mask to select some of these tiles.
local tile1 = b.rectangle(10, 10)
tile1 = b.change_tile(tile1, true, 'sand-1')
local tile2 = b.rectangle(8, 8)
tile2 = b.change_tile(tile2, true, 'grass-1')
local tile = b.any {tile2, tile1}
local pattern = {{tile}}
local tile_grid = b.grid_pattern(pattern, 1, 1, 10, 10)
tile_grid = b.translate(tile_grid, 5, 5)

-- sets the ore value depending upon X, Y coordinate
local value = b.manhattan_value

local function non_transform(shape)
    return shape
end

local function uranium_transform(shape)
    return b.scale(shape, 0.5)
end

local function oil_transform(shape)
    shape = b.scale(shape, 0.5)
    return b.throttle_world_xy(shape, 1, 4, 1, 4)
end

local function empty_transform()
    return b.empty_shape
end

local ores = {
    {transform = non_transform, resource = 'iron-ore', value = value(1000, 10), weight = 16},
    {transform = non_transform, resource = 'copper-ore', value = value(800, 10), weight = 10},
    {transform = non_transform, resource = 'stone', value = value(500, 10), weight = 3},
    {transform = non_transform, resource = 'coal', value = value(600, 10), weight = 5},
    {transform = uranium_transform, resource = 'uranium-ore', value = value(200, 10), weight = 3},
    {transform = oil_transform, resource = 'crude-oil', value = value(100000, 5000), weight = 6},
    {transform = empty_transform, weight = 300}
}

local random = Random.new(ore_seed1, ore_seed2)

local total_weights = {}
local t = 0
for _, v in ipairs(ores) do
    t = t + v.weight
    insert(total_weights, t)
end

local p_cols = 50
local p_rows = 50
local ore_pattern = {}

for _ = 1, p_rows do
    local row = {}
    insert(ore_pattern, row)
    for _ = 1, p_cols do
        local shape = b.rectangle(2, 2)

        local i = random:next_int(1, t)
        local index = table.binary_search(total_weights, i)
        if (index < 0) then
            index = bit32.bnot(index)
        end

        local ore_data = ores[index]
        shape = ore_data.transform(shape)
        local ore = b.resource(shape, ore_data.resource, ore_data.value)

        insert(row, ore)
    end
end
local ore_shape = b.grid_pattern(ore_pattern, 50, 50, 10, 10)

-- Apply the Sierpinski carpet shape to the tiles as a mask
local map = b.choose(sierpinski, tile_grid, b.empty_shape)
map = b.translate(map, -5, 5)

-- Make a sea to place underneath the tiles to fill the voids. Gives players somewhere to get water for power
local sea = b.change_tile(b.full_shape, true, 'water')
sea = b.choose(quadrant, sea, b.empty_shape)
sea = b.fish(sea, 0.00125)

map = b.any {map, sea}
map = b.apply_entity(map, ore_shape)

local function on_init()
    local player_force = game.forces.player
    player_force.technologies['landfill'].enabled = false -- disable landfill
end

Event.on_init(on_init)

return map
