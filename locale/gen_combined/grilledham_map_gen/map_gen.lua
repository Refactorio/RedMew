require("locale.gen_combined.grilledham_map_gen.builders")

function run_combined_module(event)

    if MAP_GEN == nil then
        game.print("MAP_GEN not set")
        return
    end

    local area = event.area
	local surface = event.surface
    MAP_GEN_SURFACE = surface
	local tiles = {}
	local entities = {}

    local top_x = area.left_top.x
    local top_y = area.left_top.y

    for y = top_y, top_y + 31 do
        for x = top_x, top_x + 31 do

            -- local coords need to be 'centered' to allow for correct rotation and scaling.
            local tile, entity = MAP_GEN(x + 0.5, y + 0.5, x, y)

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
    surface.set_tiles(tiles, false)

    -- set entities
    for _, v in ipairs(entities) do
		if surface.can_place_entity(v) then
			surface.create_entity(v)
		end
	end
end
