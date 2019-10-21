-- Snakier Swamp by Soggs
local b = require 'map_gen.shared.builders'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'
local ceil = math.ceil
local min = math.min

-- Disable Landfill by default
local Event = require 'utils.event'
Event.on_init(
    function()
       game.forces['player'].technologies['landfill'].enabled = false
    end
)
--input
local divider_tile = 'water-mud'
local path_width = 30
local path_length = 120
local turns = 6 -- must be even; 0 makes a normal ribbon world
local divider_width = 10
local water_height = 60 -- setting it to 0 will eliminate the water border; make sure to add another source of water if you do so

--derived
local path_height = path_width * (turns + 1) + divider_width * (turns)
local tile_width = (path_width + path_length + divider_width) * 2
local tile_height = path_height + water_height * 2

local height_setting = {
        height = tile_height
}

RS.set_map_gen_settings(
    {
		MGSP.water_none,
        height_setting
    }
)


-- Snakey path
local divider_vertical = b.rectangle(divider_width, path_height - path_width)
local divider_horizontal = b.rectangle(tile_width - path_width * 2 - divider_width, divider_width)


local p = {}
table.insert(p, b.translate(divider_vertical, 0, path_width/2))
for i = 0, turns/2 - 1, 1 do
    table.insert(p, b.translate(divider_horizontal, 0, (2*i+1) * path_width + (2*i+0.5) * divider_width - path_height/2))
end
local divider = b.any(p)


local path = b.any
    {
        divider,
        b.translate(b.flip_y(divider), tile_width/2, 0),
        b.translate(b.flip_y(divider), -tile_width/2, 0)
    }

path = b.change_tile(path, true, divider_tile)
path = b.remove_map_gen_decoratives(path)

-- Water Border
local water_rectangle = b.rectangle(tile_width, water_height)
local water_way = b.any
    {
        b.translate(water_rectangle, 0, (path_height+water_height)/2),
        b.translate(water_rectangle, 0, -(path_height+water_height)/2)
    }
water_way = b.change_tile(water_way, true, 'water')

local tile = b.any {path, water_way}
local grid = b.single_x_pattern(tile, tile_width)
local map = b.if_else(grid, b.full_shape)

--Starting resources
local max_height = 50
local max_width = 50
local ore_rectangle = b.rectangle(min(path_width-2, max_height), min(path_width-2, max_width))
local ore_spacing = min(path_width, max_height+2)
local function amount(a)
    local value = ceil(a /min(path_width-2, max_height) /min(path_width-2, max_width))
    return
        function (_, _)
            return value
        end
end

--Clean area of other ressources
ore_rectangle = b.remove_map_gen_resources(ore_rectangle)

-- Spawn in starting ressources

local iron = b.translate(ore_rectangle, ore_spacing * 0.5 + divider_width/2 + path_width, 0)
iron = b.resource(iron, 'iron-ore', amount(750000))
local copper = b.translate(ore_rectangle, -(ore_spacing * 0.5 + divider_width/2 + path_width), 0)
copper = b.resource(copper, 'copper-ore', amount(500000))
local stone = b.translate(ore_rectangle, ore_spacing * 1.5 + divider_width/2 + path_width, 0)
stone = b.resource(stone, 'stone', amount(250000))
local coal = b.translate(ore_rectangle, -(ore_spacing * 1.5 + divider_width/2 + path_width), 0)
coal = b.resource(coal, 'coal', amount(350000))

local starting_resources =
    {
        iron,
        copper,
        stone,
        coal
    }

map = b.apply_entities(map, starting_resources)

map = b.translate(map, -divider_width, 0) -- Move spawn somewhere with land
return b.fish(map, 0.0025)
