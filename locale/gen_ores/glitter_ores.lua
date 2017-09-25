-- Glittery ores, provide a mix value, and all patches outside uranium will be a full mix.
-- Gameplay comment 9/22/2017 -- After a playtest,  we learned that at 1:1 ratio of iron/copper 
-- creates a LARGE amount of extra copper from the start. Also a 4:1 ratio for stone is quite heavy.
-- Suggest modifying the sprinkle_factor out of 100% to make for a less game about warehousing ore, 
-- to one about picking patches that are mostly the preferred ore, along with a % of the wrong ores.
glitter_debug = false

function run_ores_module_setup()
   if glitter_debug then game.print("Glitter Ore: debug is enabled; module setup;") end

   ore_mix = {}
   ore_ratios = {
      ["iron-ore"] = 1.0,
      ["coal"] = 0.5,
      ["copper-ore"] = 1,
      ["stone"] = 0.25
   }
   -- 1-100% chance of sprinkling any individual ore
   sprinkle_factor = 100

   -- Sets the buffer distance before ores are scrambled
   starting_buffer = 125
   
   ore_mix_max = 0
   -- Prime the array
   for a,b in pairs(ore_ratios) do
      for i=1,(b*1000) do
         ore_mix_max = ore_mix_max + 1
         ore_mix[ore_mix_max] = a
      end
   end
end

run_ores_module_setup()

--generate ores for entire chunk
function run_ores_module(event)
	local area = event.area
	local surface = event.surface
   
	if glitter_debug then 
      game.print("Glitter ore: chunk generation") 
   end

   local chunk_mid = {(area.left_top.x + area.right_bottom.x) / 2, (area.left_top.y + area.right_bottom.y) / 2}
   local distance = math.sqrt(chunk_mid[1] * chunk_mid[1] + chunk_mid[2] * chunk_mid[2])
   if distance > starting_buffer then 
      local entities = surface.find_entities_filtered{type="resource", area=area}

       for _, entity in ipairs(entities) do
         if ore_ratios[entity.name] ~= nil then
            -- Roll to sprinkle_factor
            if sprinkle_factor < 100 then
               sprinkle_random = math.random(1,100)
               should_sprinkle = sprinkle_random <= sprinkle_factor
            else 
               should_sprinkle = true
            end
            if should_sprinkle then
               local new_name = nil
               
               --- Use the ratios to randomly select an ore
               new_ore_random = math.random(1,ore_mix_max)
               new_name = ore_mix[new_ore_random]

               local position_old = entity.position
               local amount_old = entity.amount

               local surface = entity.surface
               entity.destroy()
               local new_entity = surface.create_entity{name = new_name, position = position_old, force="neutral", amount=amount_old}
            end
         end   
      end
    end
end
