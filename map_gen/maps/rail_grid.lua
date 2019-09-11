-- Map by Jayefuu, grilledham, R.Nukem and Soggs

-- Notes:
-- - We recommend playing with RSO to force expansion by rail
-- - If playing with mods, do not use FARL, the rail placing mechanic will not work with this map

-- Dependencies
local b = require 'map_gen.shared.builders'
local Random = require 'map_gen.shared.random'
local table = require 'utils.table'
local Event = require 'utils.event'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'
local MSP = require 'resources.map_settings'
local degrees = require "utils.math".degrees
local ScenarioInfo = require 'features.gui.info'

-- Setup surface and map settings
RS.set_map_gen_settings(
    {
        MGSP.cliff_none,
        MGSP.grass_disabled,
        MGSP.enable_water,
    }
)

ScenarioInfo.set_map_name('Rail Grid')
ScenarioInfo.set_map_description(
    [[
Nauvis' factory planners have been disappointed with the recent trend towards
rail spaghetti. As such they have enacted rules to enforce neat grid shaped
rails and crossings.
]]
)
ScenarioInfo.add_map_extra_info(
    [[
This map has green "city blocks" to enforce construction of rail in a grid
pattern.

You cannot place rail on any tile type except landfill. There is space at the
grid intersections for junctions and turnarounds. There is space for
two stations on each side of the grid.
]]
)


RS.set_spawn_position({x = 20,y = 20})

local function is_not_water_tile(x, y, world)
    local gen_tile = world.surface.get_tile(world.x, world.y)
    return not gen_tile.collides_with('water-tile')
end


local station_length = 40
local station = b.any{
    b.rectangle(station_length,18),
    b.translate(b.square_diamond(18),station_length/2,0), -- these just make it pretty
    b.translate(b.square_diamond(18),station_length/-2,0) -- these just make it pretty
}

local grid_size = 224
local path = b.any{
    b.square_diamond(40),
    b.rectangle(grid_size,6),
    b.rectangle(6,grid_size),
    b.circular_pattern(b.rotate(station,degrees(90)), 4, grid_size/3)
}

path = b.change_tile(path, true, 'landfill')            -- MUST be landfill or the rail removal event doesn't work.
local grid = b.single_grid_pattern(path, grid_size, grid_size)

local no_water_grid = b.choose(is_not_water_tile, grid, b.full_shape)

local map = b.if_else(no_water_grid, b.full_shape)
map = b.translate(map,1,1)


local tile_map ={
    ['grass-1'] = 'dirt-1',
    ['grass-2'] = 'dirt-2',
    ['grass-3'] = 'dirt-3',
    ['grass-4'] = 'dirt-4',
}

-- replace grass tiles with dirt so that the rail grid is much
for old_tile, new_tile in pairs(tile_map) do
    map = b.change_map_gen_tile(map, old_tile, new_tile)
end

-- This event removes rail and curve rail entities and removes them unless they are placed on landfill
Event.add(
    defines.events.on_built_entity,
    function(event)
        local entity = event.created_entity
        if not entity or not entity.valid then
            return
        end
        local name = entity.name

		local ghost = false
        if name == 'tile-ghost' or name == 'entity-ghost' then
            ghost = true
			ghost_name = entity.ghost_name
        end

        if (name ~= 'straight-rail') and (name ~= 'curved-rail') then
			if not ghost then
			    return
			elseif (ghost_name ~= 'straight-rail') and (ghost_name ~= 'curved-rail') then
				return
			end
        end

        -- Check the bounding box for the tile
        local status = true
        local area = entity.bounding_box
        local left_top = area.left_top
        local right_bottom = area.right_bottom
        local p = game.get_player(event.player_index)
        --check for sand under all tiles in bounding box
        for x = math.floor(left_top.x), math.floor(right_bottom.x), 1 do
            for y = math.floor(left_top.y), math.floor(right_bottom.y), 1 do
                if (p.surface.get_tile(x, y).name ~= 'landfill')then
                    status = false
                    break
                end
            end
        end
        if status == true then
            return
        else
            --destroy entity and return to player
            if not p or not p.valid then
               return
            end
            entity.destroy()
            if not ghost then
                p.insert(event.stack)
            end
        end
    end
)

-- On player join print a notice explaining the rail mechanic
local function player_joined_game(event)
    local player_index = event.player_index
    local player = game.get_player(player_index)
    if not player or not player.valid then
        return
    end

    player.print("Welcome to RedMew's Rail Grids Map. Rails can only be built on green tiles.", {r=0, g=1, b=0, a=1})
end

Event.add(defines.events.on_player_joined_game, player_joined_game)

return map
