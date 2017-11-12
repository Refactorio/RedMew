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
   local decoratives = {}

   local top_x = area.left_top.x
   local top_y = area.left_top.y

   if map_gen_decoratives then
      for _, e in pairs(surface.find_entities_filtered{area=area, type="simple-entity"}) do
   		e.destroy()
      end
      for _, e in pairs(surface.find_entities_filtered{area=area, type="tree"}) do
   		e.destroy()
      end
   end


   for y = top_y, top_y + 31 do
      for x = top_x, top_x + 31 do

         -- local coords need to be 'centered' to allow for correct rotation and scaling.
         local tile, entity = MAP_GEN(x + 0.5, y + 0.5, x, y)

         if type(tile) == "boolean" and not tile then
            table.insert( tiles, {name = "out-of-map", position = {x, y}} )
         elseif type(tile) == "string" then
            table.insert( tiles, {name = tile, position = {x, y}} )

            if map_gen_decoratives then
               tile_decoratives = check_decorative(tile, x, y)
               for _,tbl in ipairs(tile_decoratives) do
                  table.insert(decoratives, tbl)
               end


               tile_entities = check_entities(tile, x, y)
               for _,entity in ipairs(tile_entities) do
                  table.insert(entities, entity)
               end
            end
         end

         if entity then
            table.insert(entities, entity)
         end

      end
   end

   -- set tiles.
   surface.set_tiles(tiles, false)

   -- set entities
   for _, entity in ipairs(entities) do
      if surface.can_place_entity {name=entity.name, position=entity.position} then
         surface.create_entity {name=entity.name, position=entity.position}
      end
   end

	for _,deco in pairs(decoratives) do
      if deco ~= nil then
		    surface.create_decoratives({check_collision=true, decoratives={deco}})
      end
	end

end

local decorative_options = {
   ["concrete"] = {},
   ["deepwater"] = {},
   ["deepwater-green"] = {},
   ["dirt"] = {},
   ["dirt-dark"] = {},
   ["grass"] = {
      {"green-carpet-grass", 3},
      {"green-hairy-grass", 7},
      {"green-bush-mini", 10},
      {"green-pita", 6},
      {"green-small-grass", 12},
      {"green-asterisk", 25},
      {"green-bush-mini", 7},
   },
   ["grass-dry"] = {},
   ["grass-medium"] = {},
   ["hazard-concrete-left"] = {},
   ["hazard-concrete-right"] = {},
   ["lab-dark-1"] = {},
   ["lab-dark-2"] = {},
   ["red-desert"] = {},
   ["red-desert-dark"] = {},
   ["sand"] = {},
   ["sand-dark"] = {},
   ["stone-path"] = {},
   ["water"] = {},
   ["water-green"] = {},
   ["out-of-map"] = {},
}

function check_decorative(tile, x, y)
   local options = decorative_options[tile]
   local tile_decoratives = {}

   for _,e in ipairs(options) do
      name = e[1]
      high_roll = e[2]
      if math.random(1, high_roll) == 1 then
         table.insert(tile_decoratives, {name=name, amount=1, position={x,y}})
      end
   end

   return tile_decoratives
end

local entity_options = {
   ["concrete"] = {},
   ["deepwater"] = {},
   ["deepwater-green"] = {},
   ["dirt"] = {},
   ["dirt-dark"] = {},
   ["grass"] = {
      {"tree-04", 400},
      {"tree-06", 150},
      {"tree-07", 400},
      {"tree-09", 1000},
      {"stone-rock", 400},
      {"green-coral", 10000},
   },
   ["grass-dry"] = {},
   ["grass-medium"] = {},
   ["hazard-concrete-left"] = {},
   ["hazard-concrete-right"] = {},
   ["lab-dark-1"] = {},
   ["lab-dark-2"] = {},
   ["red-desert"] = {},
   ["red-desert-dark"] = {},
   ["sand"] = {},
   ["sand-dark"] = {},
   ["stone-path"] = {},
   ["water"] = {},
   ["water-green"] = {},
   ["out-of-map"] = {},
}

function check_entities(tile, x, y)
   local options = entity_options[tile]
   local tile_entity_list = {}

   for _,e in ipairs(options) do
      name = e[1]
      high_roll = e[2]
      if math.random(1, high_roll) == 1 then
         table.insert(tile_entity_list, {name=name, position={x,y}})
      end
   end

   return tile_entity_list

end
