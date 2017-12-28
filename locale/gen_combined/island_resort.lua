--Author: MewMew
require "locale.gen_shared.perlin_noise"
local Thread = require "locale.utils.Thread"

local radius = 129
local radsquare = radius*radius

function run_combined_module(event)
  local entities = event.surface.find_entities(event.area)
  for _, entity in pairs(entities) do
    if entity.type == "simple-entity" or entity.type == "resource" or entity.type == "tree" then
      entity.destroy()
    end
  end

  Thread.queue_action("run_island_init", {} )
  for x = 0, 31, 1 do
 		Thread.queue_action("run_island", {area = event.area, surface = event.surface, x = x})
      -- run_island( {area = event.area, surface = event.surface, x = x})
 	end
   Thread.queue_action("run_island_place_tiles", {surface = event.surface})
   Thread.queue_action("run_chart_update", {area = event.area, surface = event.surface}
end


global.island_tiles_hold = {}
global.island_decoratives_hold = {}

function run_island_init(params)
   global.island_tiles_hold = {}
   global.island_decoratives_hold = {}
end

function run_island_place_tiles(params)
	local surface = params.surface
   surface.set_tiles(global.island_tiles_hold)
   for _,deco in pairs(global.island_decoratives_hold) do
     surface.create_decoratives{check_collision=false, decoratives={deco}}
   end
end

function run_chart_update(params)
   local x = params.area.left_top.x / 32
   local y = params.area.left_top.y / 32
      if game.forces.player.is_chunk_charted(params.surface, {x,y} ) then
         -- Don't use full area, otherwise adjacent chunks get charted
         game.forces.player.chart(params.surface, {{  params.area.left_top.x,  params.area.left_top.y}, { params.area.left_top.x+30,  params.area.left_top.y+30} } )
      end
end

function run_island( params )
	local area = params.area
	local surface = params.surface

	local x = params.x
	local pos_x = area.left_top.x + x

   for y = 0, 31, 1 do
      local pos_y = area.left_top.y + y
      local seed = surface.map_gen_settings.seed
      local seed_increment = 10000

      seed = seed + seed_increment
      local noise_island_starting_1 = perlin:noise(((pos_x+seed)/30),((pos_y+seed)/30),0)
      seed = seed + seed_increment
      local noise_island_starting_2 = perlin:noise(((pos_x+seed)/10),((pos_y+seed)/10),0)
      seed = seed + seed_increment
      local noise_island_starting = noise_island_starting_1 + (noise_island_starting_2 * 0.3)
      noise_island_starting = noise_island_starting * 8000

      seed = seed + seed_increment
      local noise_island_iron_and_copper_1 = perlin:noise(((pos_x+seed)/300),((pos_y+seed)/300),0)
      seed = seed + seed_increment
      local noise_island_iron_and_copper_2 = perlin:noise(((pos_x+seed)/40),((pos_y+seed)/40),0)
      seed = seed + seed_increment
      local noise_island_iron_and_copper_3 = perlin:noise(((pos_x+seed)/10),((pos_y+seed)/10),0)
      local noise_island_iron_and_copper = noise_island_iron_and_copper_1 + (noise_island_iron_and_copper_2 * 0.1) + (noise_island_iron_and_copper_3 * 0.05)

      seed = seed + seed_increment
      local noise_island_stone_and_coal_1 = perlin:noise(((pos_x+seed)/300),((pos_y+seed)/300),0)
      seed = seed + seed_increment
      local noise_island_stone_and_coal_2 = perlin:noise(((pos_x+seed)/40),((pos_y+seed)/40),0)
      seed = seed + seed_increment
      local noise_island_stone_and_coal_3 = perlin:noise(((pos_x+seed)/10),((pos_y+seed)/10),0)
      local noise_island_stone_and_coal = noise_island_stone_and_coal_1 + (noise_island_stone_and_coal_2 * 0.1) + (noise_island_stone_and_coal_3 * 0.05)

      seed = seed + seed_increment
      local noise_island_oil_and_uranium_1 = perlin:noise(((pos_x+seed)/300),((pos_y+seed)/300),0)
      seed = seed + seed_increment
      local noise_island_oil_and_uranium_2 = perlin:noise(((pos_x+seed)/40),((pos_y+seed)/40),0)
      seed = seed + seed_increment
      local noise_island_oil_and_uranium_3 = perlin:noise(((pos_x+seed)/10),((pos_y+seed)/10),0)
      local noise_island_oil_and_uranium = noise_island_oil_and_uranium_1 + (noise_island_oil_and_uranium_2 * 0.1) + (noise_island_oil_and_uranium_3 * 0.05)


      seed = seed + seed_increment
      local noise_island_resource = perlin:noise(((pos_x+seed)/60),((pos_y+seed)/60),0)
      seed = seed + seed_increment
      local noise_island_resource_2 = perlin:noise(((pos_x+seed)/10),((pos_y+seed)/10),0)
      noise_island_resource = noise_island_resource + noise_island_resource_2 * 0.15

      seed = seed + seed_increment
      local noise_trees_1 = perlin:noise(((pos_x+seed)/30),((pos_y+seed)/30),0)
      seed = seed + seed_increment
      local noise_trees_2 = perlin:noise(((pos_x+seed)/10),((pos_y+seed)/10),0)
      local noise_trees = noise_trees_1 + noise_trees_2 * 0.5

      seed = seed + seed_increment
      local noise_decoratives_1 = perlin:noise(((pos_x+seed)/50),((pos_y+seed)/50),0)
      seed = seed + seed_increment
      local noise_decoratives_2 = perlin:noise(((pos_x+seed)/10),((pos_y+seed)/10),0)
      local noise_decoratives = noise_decoratives_1 + noise_decoratives_2 * 0.5

      local tile_to_insert = "water"

      --Create starting Island
      local tile_distance_to_center = nil
      local a = pos_y * pos_y
      local b = pos_x * pos_x
      local tile_distance_to_center = a + b
      if tile_distance_to_center + noise_island_starting <= radsquare then
          tile_to_insert = "grass"
      end

      if tile_distance_to_center + noise_island_starting > radsquare + 20000 then
        --Placement of Island Tiles

        if noise_island_oil_and_uranium > 0.53 then
          tile_to_insert = "red-desert"
        end
        if noise_island_oil_and_uranium < -0.53 then
          tile_to_insert = "red-desert-dark"
        end

        if noise_island_stone_and_coal > 0.47 then
          tile_to_insert = "grass-medium"
        end
        if noise_island_stone_and_coal < -0.47 then
          tile_to_insert = "grass-dry"
        end

        if noise_island_iron_and_copper > 0.47 then
          tile_to_insert = "sand"
        end
        if noise_island_iron_and_copper < -0.47 then
          tile_to_insert = "sand-dark"
        end

      end

      --Placement of Trees
      if tile_to_insert ~= "water" then
        if noise_trees > 0.1 then
          local tree = "tree-01"
          if tile_to_insert == "grass" then
            tree = "tree-05"
          end
          if tile_to_insert == "grass-dry" then
            tree = "tree-02"
          end
          if tile_to_insert == "grass-medium" then
            tree = "tree-04"
          end
          if tile_to_insert == "sand" then
            tree = "tree-07"
          end
          if tile_to_insert == "sand-dark" then
            tree = "dry-hairy-tree"
          end
          if tile_to_insert == "red-desert" then
            tree = "dry-tree"
          end
          if tile_to_insert == "red-desert-dark" then
            if math.random(1,3) == 1 then
              tree = "red-desert-rock-huge-01"
            else
              tree = "red-desert-rock-big-01"
            end
          end
          if math.random(1,8) == 1 then
            if surface.can_place_entity {name=tree, position={pos_x,pos_y}} then
                surface.create_entity {name=tree, position={pos_x,pos_y}}
            end
          end
        end
      end

      if tile_to_insert == "sand" or tile_to_insert == "sand-dark" then
        if math.random(1,200) == 1 then
            if surface.can_place_entity {name="stone-rock", position={pos_x,pos_y}} then
                surface.create_entity {name="stone-rock", position={pos_x,pos_y}}
            end
        end
      end
      if tile_to_insert == "grass" or tile_to_insert == "grass-dry" or tile_to_insert == "grass-medium" then
        if math.random(1,2000) == 1 then
            if surface.can_place_entity {name="stone-rock", position={pos_x,pos_y}} then
                surface.create_entity {name="stone-rock", position={pos_x,pos_y}}
            end
        end
      end

      --Placement of Decoratives
      if tile_to_insert ~= "water" then
        if noise_decoratives > 0.3 then
          local decorative = "green-carpet-grass"
          if tile_to_insert == "grass" then
            decorative = "green-pita"
          end
          if tile_to_insert == "grass-dry" then
            decorative = "green-pita"
          end
          if tile_to_insert == "grass-medium" then
            decorative = "green-pita"
          end
          if tile_to_insert == "sand" then
            decorative = "green-asterisk"
          end
          if tile_to_insert == "sand-dark" then
            decorative = "green-asterisk"
          end
          if tile_to_insert == "red-desert" then
            decorative = "red-asterisk"
          end
          if tile_to_insert == "red-desert-dark" then
            decorative = "red-asterisk"
          end
          if math.random(1,5) == 1 then
            table.insert(global.island_decoratives_hold, {name=decorative, position={pos_x,pos_y}, amount=1})
          end
        end
        if tile_to_insert == "red-desert-dark" then
          if math.random(1,50) == 1 then
            table.insert(global.island_decoratives_hold, {name="red-desert-rock-medium", position={pos_x,pos_y}, amount=1})
          end
        end
      end

      --Placement of Island Resources
      if tile_to_insert ~= "water" then
        local a = pos_x
        local b = pos_y
        local c = 1
        if area.right_bottom.x < 0 then a = area.right_bottom.x * -1 end
        if area.right_bottom.y < 0 then b = area.right_bottom.y * -1 end
        if a > b	then	c = a	else c = b	end
        local resource_amount_distance_multiplicator = (((c + 1) / 75) / 75) + 1
        local noise_resource_amount_modifier = perlin:noise(((pos_x+seed)/200),((pos_y+seed)/200),0)
        local resource_amount = 1 + ((500 + (500*noise_resource_amount_modifier*0.2)) * resource_amount_distance_multiplicator)

        if tile_to_insert == "sand" or tile_to_insert == "sand-dark" then
          if noise_island_iron_and_copper > 0.5 and noise_island_resource > 0.2 then
            if surface.can_place_entity {name="iron-ore", position={pos_x,pos_y}} then
              surface.create_entity {name="iron-ore", position={pos_x,pos_y}, amount=resource_amount}
            end
          end
          if noise_island_iron_and_copper < -0.5 and noise_island_resource > 0.2 then
            if surface.can_place_entity {name="copper-ore", position={pos_x,pos_y}} then
              surface.create_entity {name="copper-ore", position={pos_x,pos_y}, amount=resource_amount}
            end
          end
        end

        if tile_to_insert == "grass-medium" or tile_to_insert == "grass-dry" then
          if noise_island_stone_and_coal > 0.5 and noise_island_resource > 0.2 then
            if surface.can_place_entity {name="stone", position={pos_x,pos_y}} then
              surface.create_entity {name="stone", position={pos_x,pos_y}, amount=resource_amount*1.5}
            end
          end
          if noise_island_stone_and_coal < -0.5 and noise_island_resource > 0.2 then
            if surface.can_place_entity {name="coal", position={pos_x,pos_y}} then
              surface.create_entity {name="coal", position={pos_x,pos_y}, amount=resource_amount}
            end
          end
        end

        if tile_to_insert == "red-desert" or tile_to_insert == "red-desert-dark" then
          if noise_island_oil_and_uranium > 0.55 and noise_island_resource > 0.25 then
            if surface.can_place_entity {name="crude-oil", position={pos_x,pos_y}} then
              if math.random(1,60) == 1 then
                surface.create_entity {name="crude-oil", position={pos_x,pos_y}, amount=resource_amount*400}
              end
            end
          end
          if noise_island_oil_and_uranium < -0.55 and noise_island_resource > 0.35 then
            if surface.can_place_entity {name="uranium-ore", position={pos_x,pos_y}} then
              surface.create_entity {name="uranium-ore", position={pos_x,pos_y}, amount=resource_amount}
            end
          end
        end
        noise_island_starting = noise_island_starting * 0.08
        --Starting Resources
        if tile_distance_to_center <= radsquare then
          if tile_distance_to_center + noise_island_starting > radsquare * 0.09 and tile_distance_to_center + noise_island_starting <= radsquare * 0.15 then
            if surface.can_place_entity {name="stone", position={pos_x,pos_y}} then
              surface.create_entity {name="stone", position={pos_x,pos_y}, amount=resource_amount*1.5}
            end
          end
          if tile_distance_to_center + noise_island_starting > radsquare * 0.05 and tile_distance_to_center + noise_island_starting <= radsquare * 0.09 then
            if surface.can_place_entity {name="coal", position={pos_x,pos_y}} then
              surface.create_entity {name="coal", position={pos_x,pos_y}, amount=resource_amount*1.5}
            end
          end
          if tile_distance_to_center + noise_island_starting > radsquare * 0.02 and tile_distance_to_center + noise_island_starting <= radsquare * 0.05 then
            if surface.can_place_entity {name="iron-ore", position={pos_x,pos_y}} then
              surface.create_entity {name="iron-ore", position={pos_x,pos_y}, amount=resource_amount*1.5}
            end
          end
          if tile_distance_to_center + noise_island_starting > radsquare * 0.003 and tile_distance_to_center + noise_island_starting <= radsquare * 0.02 then
            if surface.can_place_entity {name="copper-ore", position={pos_x,pos_y}} then
              surface.create_entity {name="copper-ore", position={pos_x,pos_y}, amount=resource_amount*1.5}
            end
          end
          if tile_distance_to_center + noise_island_starting <= radsquare * 0.002 then
            if surface.can_place_entity {name="crude-oil", position={pos_x,pos_y}} then
              if math.random(1,16) == 1 then surface.create_entity {name="crude-oil", position={pos_x,pos_y}, amount=resource_amount*400} end
            end
          end
        end
      end

      if tile_to_insert == "water" then
        local a = pos_x + 1
        table.insert(global.island_tiles_hold, {name = tile_to_insert, position = {a,pos_y}})
        local a = pos_y + 1
        table.insert(global.island_tiles_hold, {name = tile_to_insert, position = {pos_x,a}})
        local a = pos_x - 1
        table.insert(global.island_tiles_hold, {name = tile_to_insert, position = {a,pos_y}})
        local a = pos_y - 1
        table.insert(global.island_tiles_hold, {name = tile_to_insert, position = {pos_x,a}})
      end

      table.insert(global.island_tiles_hold, {name = tile_to_insert, position = {pos_x,pos_y}})
  end

end
