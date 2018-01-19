require "map_gencombined.grilledham_map_gen.builders"

local pic = require "map_gendata.UK"
local pic = decompress(pic)
local map = picture_builder(pic)

-- this changes the size of the map
map = scale(map, 2, 2)

-- this moves the map, effectively changing the spawn point.
map = translate(map, 0, 10)

-- this sets the tile outside the bounds of the map to deepwater, remove this and it will be void.
map = change_tile(map, false, "deepwater")

function run_combined_module(event)
    local area = event.area
	local surface = event.surface
    MAP_GEN_SURFACE = surface
	local tiles = {}
	local entities = {}

    local top_x = area.left_top.x
    local top_y = area.left_top.y

    -- place tiles over the edge of chunks to reduce tile artefacts on chunk boundaries.
    for y = top_y - 1, top_y + 32 do
        for x = top_x - 1, top_x + 32 do

            -- local coords need to be 'centered' to allow for correct rotation and scaling.
            local tile, entity = map(x + 0.5, y + 0.5, x, y)

            if type(tile) == "boolean" and not tile then
                table.insert( tiles, {name = "out-of-map", position = {x, y}} )
            elseif type(tile) == "string" then
                table.insert( tiles, {name = tile, position = {x, y}} )
            end

            if entity then
                table.insert(entities, entity)
            end
        end
    end

    -- set tiles.
    surface.set_tiles(tiles, true)

    -- set entities
    for _, v in ipairs(entities) do
		if surface.can_place_entity(v) then
			surface.create_entity(v)
		end
	end
end
