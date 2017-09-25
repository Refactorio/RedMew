-- Drops a grid of concrete, hazard and brick along the chunk edges

local function run_terrain_module_setup()
   grid = {}
   grid_widths = {
      ["concrete"] = 2,
      ["hazard-concrete-left"] = 1,
      ["stone-path"] = 1
   }
   grid_chunk_size = 3

   grid_width = 0
   -- Prime the array
   for a,b in pairs(grid_widths) do
      for i=1, b do
         grid_width = grid_width + 1
         grid[grid_width] = a
      end
   end
end

run_terrain_module_setup()

function run_terrain_module(event)
   -- Draw the grid
   -- concrete width - 3, hazard = 1, brick = 2
   local surface = event.surface
   local tiles = {}
   local tile

   local rel_x = event.area.left_top.x
   local rel_y = event.area.left_top.y

   local y = rel_y
   local x = 0

   local do_top = ( ( ( rel_y / 32 ) % grid_chunk_size ) == 0 )
   local do_bottom =  ( ( ( rel_y / 32 ) % grid_chunk_size ) == ( grid_chunk_size - 1) )
   local do_left = ( ( ( rel_x / 32 ) % grid_chunk_size ) == 0 )
   local do_right = ( ( ( rel_x / 32 ) % grid_chunk_size ) == ( grid_chunk_size - 1) )
   local do_corner_tl = do_top and do_left
   local do_corner_tr = do_top and do_right
   local do_corner_bl =  do_bottom and do_left
   local do_corner_br =  do_bottom and do_right

   -- Walk the chunk edge
   for y=rel_y, rel_y+31 do
      -- Along the left
      if ( do_left ) then
         for pos = 1, grid_width do
            tile_name = grid[grid_width+1 - pos]

            position = {rel_x + grid_width - pos, y}
            tile = surface.get_tile( position )
            if tile.name ~= "out-of-map" and tile.name ~= "water" then
               table.insert(tiles, {name = tile_name, position = position})
            end
         end
      end

      if ( do_right ) then
         -- Along the right
         for pos = 1, grid_width do
            tile_name = grid[grid_width+1 - pos]

            position = {pos + rel_x + 31 - grid_width, y}
            tile = surface.get_tile( position )
            if tile.name ~= "out-of-map" and tile.name ~= "water" then
               table.insert(tiles, {name = tile_name, position = position})
            end
         end
      end
   end

   -- Top/bottom Edges
   for x=rel_x, rel_x + 31 do
      -- Along the top
      if ( do_top ) then
         for pos = 1, grid_width do
            tile_name = grid[grid_width+1 - pos]

            position = {x, rel_y + grid_width - pos}
            tile = surface.get_tile( position )
            if tile.name ~= "out-of-map" and tile.name ~= "water" then
               table.insert(tiles, {name = tile_name, position = position})
            end
         end
      end

      if (do_bottom) then
         -- Along the bottom
         for pos = 1, grid_width do
            tile_name = grid[grid_width+1 - pos]
            position = {x, pos + rel_y + 31 - grid_width}
            tile = surface.get_tile( position )
            if tile.name ~= "out-of-map" and tile.name ~= "water" then
               table.insert(tiles, {name = tile_name, position = position})
            end
         end
      end
   end

   -- clean up corners
   for pos_x = 1, grid_width do
      for pos_y = 1, grid_width do
         if pos_x < pos_y then
            tile_name = grid[pos_x]
         else
            tile_name = grid[pos_y]
         end

         if ( do_corner_tl ) then
            -- Top Left
            position = {rel_x - 1 + pos_x, rel_y - 1 + pos_y}
            tile = surface.get_tile( position )
            if tile.name ~= "out-of-map" and tile.name ~= "water" then
               table.insert(tiles, {name = tile_name, position=position})
            end
         end

         if ( do_corner_tr ) then
            -- Top Right
            position = {rel_x + 32 - pos_x, rel_y - 1 + pos_y}
            tile = surface.get_tile( position )
            if tile.name ~= "out-of-map" and tile.name ~= "water" then
               table.insert(tiles, {name = tile_name, position=position})
            end
         end

         if ( do_corner_bl ) then
            -- Bottom Left
            position = {rel_x - 1 + pos_x, rel_y + 32 - pos_y}
            tile = surface.get_tile( position )
            if tile.name ~= "out-of-map" and tile.name ~= "water" then
               table.insert(tiles, {name = tile_name, position=position})
            end
         end

         if ( do_corner_br ) then
            -- Bottom right
            position = {rel_x + 32 - pos_x, rel_y + 32 - pos_y}
            tile = surface.get_tile( position )
            if tile.name ~= "out-of-map" and tile.name ~= "water" then
               table.insert(tiles, {name = tile_name, position=position})
            end
         end
      end
   end

  surface.set_tiles(tiles,true)
end
