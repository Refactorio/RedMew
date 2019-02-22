--Hilbert Sand Trap Map, by Jayefuu, R. Nukem, and grilledham

local b = require 'map_gen.shared.builders'
local degrees = require "utils.math".degrees
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'
--https://www.fractalus.com/kerry/tutorials/hilbert/hilbert-tutorial.html
-- Setup the scenario map information because everyone gets upset if you don't
local ScenarioInfo = require 'features.gui.info'
ScenarioInfo.set_map_name('Hilbert\'s Sand Trap')
ScenarioInfo.set_map_description('You have crash landed in the middle of Hilbert\'s Labyrinth! Surrounded by quicksand and biters you must survive long enough to launch a rocket.')
ScenarioInfo.set_map_extra_info('Only the native grasses are suitable to build on. Ores and trees have sunk into the sand, but biters have adapted to live happily in the barren landscape. Some even speak of a Hydra living deep within the desert. \n\n Map created by R. Nukem and Jayefuu, with help from grilledham and the rest of the Redmew admin team.')
--enable Hydra
local hail_hydra = global.config.hail_hydra
hail_hydra.enabled = true
-- define map settings
local ore_settings = {
	autoplace_controls = {
		coal = {
			frequency = 'very-high',
			richness = 'normal',
			size = 'small'
		},
		['copper-ore'] = {
			frequency = 'very-high',
			richness = 'normal',
			size = 'normal'
		},
		['crude-oil'] = {
			frequency = 'very-high',
			richness = 'low',
			size = 'small'
		},
		['iron-ore'] = {
			frequency = 'very-high',
			richness = 'normal',
			size = 'normal'
		},
		stone = {
			frequency = 'very-high',
			richness = 'low',
			size = 'small'
		},
		['uranium-ore'] = {
			frequency = 'very-high',
			richness = 'very-low',
			size = 'very-small'
		}
	}
}
local biter_settings = {
	autoplace_controls = {
		['enemy-base'] = {
			frequency = 'very-high',
			richness = 'very-high',
			size = 'very-high'
		}
	}
}
local tree_settings = {
	autoplace_controls = {
		trees = {
			frequency = 'very-high',
			richness = 'normal',
			size = 'normal'
		}
    }
}
local starting_area = {
    starting_area = 'very-small'
}
local water_settings = {
	terrain_segmentation = 'high',
    water = 'low'
}	
--Set map settings	
RS.set_map_gen_settings(
    {
        MGSP.cliff_none,
		MGSP.grass_only,
		ore_settings,
		biter_settings,
		starting_area,
		tree_settings,
		water_settings,
		map_seed
    }
)
--remove resources from sand
local function no_resources(_, _, world, tile)
    local entites =
        world.surface.find_entities_filtered(
        {type = 'resource', area = {{world.x, world.y}, {world.x + 1, world.y + 1}}}
    )
    for i = 1, #entites do
        entites[i].destroy()
    end
    return tile
end
--remove trees from sand
local function no_trees(_, _, world, tile)
    local entites =
        world.surface.find_entities_filtered(
        {type = 'tree', area = {{world.x, world.y}, {world.x + 1, world.y + 1}}}
    )
    for i = 1, #entites do
        entites[i].destroy()
    end
    return tile
end
--start hilbert design
local line_1 = b.translate(b.rectangle(6, 16), -5, 0)
local tier_1 =
    b.any {
    line_1,
    b.rotate(line_1, degrees(-90)),
    b.rotate(line_1, degrees(-180))
}
local hilbert_levels = 2 -- don't change to 3, the algorithm is broken somewhere
local pattern = tier_1
local var = 20
for i = 1, hilbert_levels do
    -- do the rotation stuff
    pattern =
        b.any {
        pattern,
        b.translate(b.flip_x(pattern), i * var, 0),
        b.translate(b.rotate(pattern, degrees(90)), i * var, i * var),
        b.translate(b.rotate(pattern, degrees(-90)), 0, i * var)
    }
    -- translate the pattern so that the connecting pieces are easier to add
    pattern = b.translate(pattern, -0.5 * i * var, -0.5 * i * var)

    -- add the 3 connecting pieces
    pattern =
        b.any {
        pattern,
        b.translate(line_1, (10 * (i - 1) + (10 * i)) * -1, 0),
        b.translate(b.rotate(line_1, degrees(180)), (10 * (i - 1) + (10 * i)), 0),
        b.rotate(line_1, degrees(-90))
        --b.translate(line_1,-10,0)
    }
end
pattern =
    b.any {
    pattern,
    b.translate(b.rotate(line_1, degrees(90)), -40, 30),
    b.translate(b.rotate(line_1, degrees(90)), 40, 30)
}
-- Tile map in X direction
local function ribbon(x, y)
    local abs_x = math.abs(x)
    local abs_y = math.abs(y)
    return (abs_y < 40)
end
ribbon = b.change_tile(ribbon, true, 'sand-1')
ribbon = b.apply_effect(ribbon, no_resources)
ribbon = b.apply_effect(ribbon, no_trees)
ribbon = b.translate(ribbon, 0, 6)
pattern = b.translate(pattern, 0, 5)
local hilbert = b.single_x_pattern(pattern, 80)
local map = b.any {hilbert, ribbon}
map = b.scale(map, 10, 10)
-- make starting area
local start_region = b.rectangle(160,60)
map = b.subtract(map, start_region)
start_region = b.change_tile(start_region,true, 'grass-1')
start_region = b.apply_effect(start_region, no_resources)
start_water = b.change_tile(b.circle(5),true, 'water')
map = b.any{start_water,start_region,map}
--make starting ores
local value = b.manhattan_value
local ore_shape = b.scale(b.circle(30), 0.15)
local start_ore = b.circle(30)
local start_iron = b.resource(start_ore, 'iron-ore', value(1000, 0))
local start_copper = b.resource(start_ore, 'copper-ore', value(750, 0))
local start_coal = b.resource(start_ore, 'coal', value(500, 0))
local start_stone = b.resource(start_ore, 'stone', value(250, 0))
start_ore = b.segment_pattern({start_coal, start_stone, start_copper, start_iron})
ore_shape = b.choose(b.circle(30), start_ore, ore_shape)

--apply starting ores to map
map = b.apply_entity(map, ore_shape)
--shift spawn so player doesn't die to start water
map = b.translate(map, 0, -10)

-- -- Untested Code for not building on sand. However, this requires plague's entity restriction module
-- -- Enable this section when the entity restriction modules is finalized
-- -- Make sure this works on tiles if needed, otherwise keep function below
-- local RestrictEntities = require 'map_gen.shared.entity_placement_restriction'

-- local function sand_trap(entity)
-- local Game = require 'utils.game'
-- local p = Game.get_player_by_index(event.player_index)
--
-- local status = true
-- {{x1, y1},{x2,y2}} = entity.bounding_box
--
-- for x=x1,x2,1 do
-- for y = y1, y2,1 do
-- if utils.game.player.surface.get_tile(x,y).name == 'sand-1' then
-- status = false
-- break
-- end
-- end
-- end
-- return status
-- end

-- RestrictEntities.set_keep_alive_callback(sand_trap)

-- substitute until entity restriction module is finished.
local Event = require 'utils.event'
local Game = require 'utils.game'
--Ban entities from sand-1
Event.add(
    defines.events.on_built_entity,
    function(event)
        local entity = event.created_entity
        if not entity or not entity.valid then
            return
        end
        local name = entity.name
		local tile_ghost = false
		if name == 'tile-ghost' then
			tile_ghost = true
		end
        local ghost = false
        if name == 'entity-ghost' then
            name = entity.ghost_name
            ghost = true
        end
        -- Check the bounding box for the tile
        local status = true
        local area = entity.bounding_box
        local left_top = area.left_top
        local right_bottom = area.right_bottom
        local p = Game.get_player_by_index(event.player_index)
		--check for sand under all tiles in bounding box
        for x = math.floor(left_top.x), math.floor(right_bottom.x), 1 do
            for y = math.floor(left_top.y), math.floor(right_bottom.y), 1 do
                if p.surface.get_tile(x, y).name == 'sand-1' then
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
            if not ghost and not tile_ghost then
                p.insert(event.stack)
            end
        end
    end
)
-- Ban tiles from sand-1
Event.add(
    defines.events.on_player_built_tile,
    function(event)
		local player = (require 'utils.game').get_player_by_index(event.player_index)
		if not player or not player.valid then
			return
		end
		local tiles = event.tiles
		local replace_tiles = {}
		local refund_count = 0
		for i = 1, #tiles do
			local tile = tiles[i]
			local old_name = tile.old_tile.name
			if old_name == 'sand-1' then
				tile.name = 'sand-1'
				replace_tiles[#replace_tiles + 1] = tile
				refund_count = refund_count + 1
			end
		end
		if #replace_tiles > 0 then
			player.surface.set_tiles(replace_tiles, true)
		end
		player.surface.set_tiles(replace_tiles, true)
		player.insert {name = event.item.name, count = refund_count}
	end
)
return map
