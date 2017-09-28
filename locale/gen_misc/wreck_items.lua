 wreck_items_module = {}

-- adds some wrecked items around the map, good for MP, reduces total resources pulled from factory, and adds incentive to push out

wreck_item_pool = {}
wreck_item_pool = {{name="iron-gear-wheel", count=32},{name="iron-plate", count=64},{name="rocket-control-unit", count=1},{name="rocket-fuel", count=7} ,{name="coal", count=8},{name="rocket-launcher", count=1},{name="rocket", count=32},{name="copper-cable", count=128},{name="land-mine", count=64},{name="railgun", count=1},{name="railgun-dart", count=128},{name="fast-inserter", count=8},{name="stack-filter-inserter", count=2},{name="belt-immunity-equipment", count=1},{name="fusion-reactor-equipment", count=1},{name="electric-engine-unit", count=8},{name="exoskeleton-equipment", count=1},{name="rocket-fuel", count=10},{name="used-up-uranium-fuel-cell", count=3},{name="uranium-fuel-cell", count=2},{name="power-armor", count=1},{name="modular-armor", count=1},{name="water-barrel", count=4},{name="sulfuric-acid-barrel", count=6},{name="crude-oil-barrel", count=8},{name="energy-shield-equipment", count=1},{name="explosive-rocket", count=32}}

local function place_entities(surface, entity_list)
	local directions = {defines.direction.north, defines.direction.east, defines.direction.south, defines.direction.west}
	for _, entity in pairs(entity_list) do
		local r = math.random(1,entity.chance)
		if r == 1 then
			if not entity.force then entity.force = "player" end
			local r = math.random(1,4)
			if surface.can_place_entity {name=entity.name, position=entity.pos, direction=directions[r], force=entity.force} then
				local e = surface.create_entity {name=entity.name, position=entity.pos, direction=directions[r], force=entity.force}
				if entity.health then
					if entity.health == "low" then e.health = ((e.health / 1000) * math.random(33,330)) end
					if entity.health == "medium" then e.health = ((e.health / 1000) * math.random(333,666)) end
					if entity.health == "high" then e.health = ((e.health / 1000) * math.random(666,999)) end
					if entity.health == "random" then e.health = ((e.health / 1000) * math.random(1,1000)) end
				end
				return true, e
			end
		end
	end
	return false
end

function wreck_items_module.on_chunk_generated(event)
	local surface = event.surface
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos_x = event.area.left_top.x + x
			local pos_y = event.area.left_top.y + y
			local pos = {x = pos_x,y = pos_y}
			local entity_list = {}

		   table.insert(entity_list, {name="big-ship-wreck-1", pos={pos_x,pos_y},chance = 35000, health="random"})
		   table.insert(entity_list, {name="big-ship-wreck-2", pos={pos_x,pos_y},chance = 45000, health="random"})
		   table.insert(entity_list, {name="big-ship-wreck-3", pos={pos_x,pos_y},chance = 55000, health="random"})

			local b, placed_entity = place_entities(surface, entity_list)
			if b == true then
				if placed_entity.name == "big-ship-wreck-1" or placed_entity.name == "big-ship-wreck-2" or placed_entity.name == "big-ship-wreck-3" then
					placed_entity.insert(wreck_item_pool[math.random(1,#wreck_item_pool)])
					placed_entity.insert(wreck_item_pool[math.random(1,#wreck_item_pool)])
					placed_entity.insert(wreck_item_pool[math.random(1,#wreck_item_pool)])
				end
			end

		end
	end
end


return wreck_items_module
