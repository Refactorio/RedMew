-- Glittery ores, provide a mix value, and all patches outside uranium will be a full mix.
-- Started with crazy ores

require "locale.gen_shared.perlin_noise"

-- local random_ores = {"iron-ore","coal","copper-ore","stone","uranium-ore"}
-- local random_dense = {1.15,0.8,1,0.9, 0.5}	--ore density reference



local glitter_debug = false
global.glitter_setup = false

local ore_mix = {}
local mix_current = 1
local ore_ratios = {
   ["iron-ore"] = 1.0,
   ["coal"] = 0.5,
   ["copper-ore"] = 1,
   ["stone"] = 0.25
}

-- Sets the buffer distance before ores are scrambled
local starting_buffer = 100

function run_ores_module_setup()
	if glitter_debug then game.print("Glitter Ore: debug is enabled; module setup;") end

   -- Prime the array
   for a,b in pairs(ore_ratios) do
      for i=1,(b*1000) do
         mix_current = mix_current + 1
         ore_mix[mix_current] = a
      end
   end
      
end

--generate ores for entire chunk
function run_ores_module(event)
   run_ores_module_setup()

	local area = event.area
	local surface = event.surface
	local tiles = {}
   
	if glitter_debug then 
      game.print("Glitter ore: chunk generation") 
      -- game.print (area.left_top)
      -- game.forces.player.chart(surface,{lefttop = {x = area.left_top.x, y = area.left_top.y}, rightbottom = {x = area.right_bottom.x, y = area.right_bottom.y}})
      
   end
     
   -- Buffer ores around the spawn -- 5 chunks

   local chunk_mid = {(area.left_top.x + area.right_bottom.x) / 2, (area.left_top.y + area.right_bottom.y) / 2}
   local distance = math.sqrt(chunk_mid[1] * chunk_mid[1] + chunk_mid[2] * chunk_mid[2])
   if distance > starting_buffer then 
      local entities = surface.find_entities_filtered{type="resource", area=area}

       for _, entity in pairs(entities) do
         if ore_ratios[entity.name] > 0 then 
            
            local new_name = nil
            
            --- Use the ratios to randomly select an ore
            new_ore_random = math.random(1,mix_current)
            new_name = ore_mix[new_ore_random]
   --         game.print(new_name)

            local position_old = entity.position
            local amount_old = entity.amount

            local surface = entity.surface
            entity.destroy()
            local new_entity = surface.create_entity{name = new_name, position = position_old, force="neutral", amount=amount_old}
         end   
      end
    end
end
