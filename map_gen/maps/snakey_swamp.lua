-- Snakey Swamp by Soggs
local b = require 'map_gen.shared.builders'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'
local ceil = math.ceil
local min = math.min

-- Disable Landfill by default
local Event = require 'utils.event'

Event.on_init(
    function()
        game.forces.player.technologies['landfill'].enabled = false
    end
)

local path_width = 30
local path_height = 200
local divider_width = 10
local water_height = 40 -- setting it to 0 eliminates the water border

local height_setting = {
    height = path_height + water_height * 2
}

RS.set_map_gen_settings(
    {
        MGSP.water_none,
        height_setting
    }
)

-- Snakey path
local tile_width = path_width * 2 + divider_width * 2

local divider = b.rectangle(divider_width, path_height - path_width)
local path =
    b.any {
    b.translate(divider, (path_width + divider_width) / 2, path_width / 2),
    b.translate(divider, -(path_width + divider_width) / 2, -path_width / 2)
}
path = b.change_tile(path, true, 'water-mud')
path = b.remove_map_gen_decoratives(path)

-- Water Border
local water_rectangle = b.rectangle(tile_width, water_height)
local water_way =
    b.any {
    b.translate(water_rectangle, 0, (path_height + water_height) / 2),
    b.translate(water_rectangle, 0, -(path_height + water_height) / 2)
}
water_way = b.change_tile(water_way, true, 'water')

local tile = b.any {path, water_way}
local grid = b.single_x_pattern(tile, tile_width)
local map = b.if_else(grid, b.full_shape)

-- Starting resources
local quarter_height = path_height / 4
local max_height = 50
local max_width = 50
local ore_rectangle = b.rectangle(min(path_width - 2, max_height), min(quarter_height - 2, max_width) - 10) -- -10 to allow space for market and other buildings
local ore_spacing = min(quarter_height, max_height + 2)
local function amount(a)
    return function(_, _)
        return ceil(a / min(path_width - 2, max_height) / min(quarter_height - 2, max_width))
    end
end

-- Removes map gen resources from the first path
local starting_zone = b.rectangle(path_width, path_height)
starting_zone = b.remove_map_gen_resources(starting_zone)

map = b.add(starting_zone, map)

-- Spawn in starting ressources

local iron = b.translate(ore_rectangle, 0, ore_spacing * 0.5)
iron = b.resource(iron, 'iron-ore', amount(750000))
local copper = b.translate(ore_rectangle, 0, -ore_spacing * 0.5)
copper = b.resource(copper, 'copper-ore', amount(500000))
local stone = b.translate(ore_rectangle, 0, ore_spacing * 1.5)
stone = b.resource(stone, 'stone', amount(250000))
local coal = b.translate(ore_rectangle, 0, -ore_spacing * 1.5)
coal = b.resource(coal, 'coal', amount(350000))

map = b.apply_entities(map, {iron, copper, stone, coal})

return b.fish(map, 0.0025)
