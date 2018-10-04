--Factorio Cave Miner -- mewmew made this --
--You can use /c map_pregen() to pre-generate the world before playing to avoid microstutter while playing.--

--[[
To do(maybe):
cliffs
standalone info
2nd biome rock labyrinth
 oil  >> spawn
explosives filled chest explosion
cliff explosives // rock mining
treasure chests get better with distance
random game events // earthquake, biters, rock treasure, messages
]]--



local simplex_noise = require 'map_gen.shared.simplex_noise'
local Event = require 'utils.event'
local math = require 'utils.math'
local market_items = require "map_gen.combined.cave_miner.market_items"
local Game = require 'utils.game'

local Info = require 'info'

Info.set_map_name('Cave Miner')
Info.set_map_description([[
Diggy Diggy Hole.
]])
Info.set_map_extra_info([[
Delve deep for greater treasures, but also face increased dangers.

Mining productivity research, will overhaul your whole mining equipment,
reinforcing your pickaxe as well as increasing the size of your backpack.

Darkness is a hazard in the mines, stay near your lamps.

Breaking rocks is exhausting work and will make you hungry.
So don´t forget to eat some fish once in a while to stay well fed.
But be careful, eating too much might have it´s consequences too...
]])


if global.scenario and global.scenario.config then
    if global.scenario.config.player_list then
        global.scenario.config.player_list.enable_coin_col = nil
    end
    if global.scenario.config.fish_market then
        global.scenario.config.fish_market.enable = nil
    end
    if global.scenario.config.paint then
        global.scenario.config.paint.enable = nil
    end
    if global.scenario.nuke_control then
        global.scenario.nuke_control.enable_autokick = nil
        global.scenario.nuke_control.enable_autoban = nil
    end
    if global.scenario.config.fish_market then
      global.scenario.config.fish_market.enable = nil
    end
end

local function create_cave_miner_button(player)
	local button = player.gui.top.add({ type = "sprite-button", name = "caver_miner_stats_toggle_button", sprite = "item/iron-axe" })
	button.style.minimal_height = 38
	button.style.minimal_width = 38
	button.style.top_padding = 2
	button.style.left_padding = 4
	button.style.right_padding = 4
	button.style.bottom_padding = 2
end

local function create_cave_miner_stats_gui(player)
	if player.gui.top["hunger_frame"] then
		player.gui.top["hunger_frame"].destroy()
	end
	if player.gui.top["caver_miner_stats_frame"] then
		player.gui.top["caver_miner_stats_frame"].destroy()
	end

	local captions = {}
	local caption_style = {{"font", "default-bold"}, {"font_color",{ r=0.63, g=0.63, b=0.63}}, {"top_padding",2}, {"left_padding",0},{"right_padding",0},{"minimal_width",0}}
	local stat_numbers = {}
	local stat_number_style = {{"font", "default-bold"}, {"font_color",{ r=0.77, g=0.77, b=0.77}}, {"top_padding",2}, {"left_padding",0},{"right_padding",0},{"minimal_width",0}}
	local separators = {}
	local separator_style = {{"font", "default-bold"}, {"font_color",{ r=0.15, g=0.15, b=0.89}}, {"top_padding",2}, {"left_padding",2},{"right_padding",2},{"minimal_width",0}}

	local frame = player.gui.top.add { type = "frame", name = "hunger_frame" }

	local str = tostring(global.player_hunger[player.name])
	str = str .. "% "
	str = str .. global.player_hunger_stages[global.player_hunger[player.name]]
	local caption_hunger = frame.add { type = "label", caption = str  }
	caption_hunger.style.font = "default-bold"
	caption_hunger.style.font_color = global.player_hunger_color_list[global.player_hunger[player.name]]
	caption_hunger.style.top_padding = 2

	local frame = player.gui.top.add { type = "frame", name = "caver_miner_stats_frame" }

	local t = frame.add { type = "table", column_count = 11 }

	captions[1] = t.add { type = "label", caption = "Ores mined:" }

	global.total_ores_mined = global.stats_ores_found + game.forces.player.item_production_statistics.get_input_count("coal") + game.forces.player.item_production_statistics.get_input_count("iron-ore") + game.forces.player.item_production_statistics.get_input_count("copper-ore") + game.forces.player.item_production_statistics.get_input_count("uranium-ore")

	stat_numbers[1] = t.add { type = "label", caption = global.total_ores_mined }

	separators[1] = t.add { type = "label", caption = "|"}

	captions[2] = t.add { type = "label", caption = "Rocks broken:" }
	stat_numbers[2] = t.add { type = "label", caption = global.stats_rocks_brocken }

	separators[2] = t.add { type = "label", caption = "|"}

	captions[3] = t.add { type = "label", caption = "Efficiency" }
	local x = math.ceil(game.forces.player.manual_mining_speed_modifier * 100 + global.player_hunger_buff[global.player_hunger[player.name]] * 100, 0)
	local str = ""
	if x > 0 then str = str .. "+" end
	str = str .. tostring(x)
	str = str .. "%"
	stat_numbers[3] = t.add { type = "label", caption = str }

	if game.forces.player.manual_mining_speed_modifier > 0 or game.forces.player.mining_drill_productivity_bonus > 0 then
		separators[3] = t.add { type = "label", caption = "|"}

		captions[5] = t.add { type = "label", caption = "Fortune" }
		local str = "+"
		str = str .. tostring(game.forces.player.mining_drill_productivity_bonus * 100)
		str = str .. "%"
		stat_numbers[4] = t.add { type = "label", caption = str }

	end

	for _, s in pairs (caption_style) do
		for _, l in pairs (captions) do
			l.style[s[1]] = s[2]
		end
	end
	for _, s in pairs (stat_number_style) do
		for _, l in pairs (stat_numbers) do
			l.style[s[1]] = s[2]
		end
	end
	for _, s in pairs (separator_style) do
		for _, l in pairs (separators) do
			l.style[s[1]] = s[2]
		end
	end
	stat_numbers[1].style.minimal_width = 9 * string.len(tostring(global.stats_ores_found))
	stat_numbers[2].style.minimal_width = 9 * string.len(tostring(global.stats_rocks_brocken))
end

local function refresh_gui()
	for _, player in pairs(game.connected_players) do
		local frame = player.gui.top["caver_miner_stats_frame"]
		if (frame) then
			frame.destroy()
			create_cave_miner_stats_gui(player)
		end
	end
end

local function treasure_chest(position)
	local p = game.surfaces[1].find_non_colliding_position("wooden-chest",position, 2,0.5)
	if not p then return end
	local e = game.surfaces[1].create_entity {name="wooden-chest",position=p, force="player"}
	e.minable = false
	local i = e.get_inventory(defines.inventory.chest)
	for x = 1, math.random(3,8), 1 do
		local loot = global.treasure_chest_raffle_table[math.random(1,#global.treasure_chest_raffle_table)]
		i.insert(loot)
	end
end

local function secret_shop(pos)
	local secret_market_items = {
    {price = {{"raw-fish", math.random(250,450)}}, offer = {type = 'give-item', item = 'combat-shotgun'}},
    {price = {{"raw-fish", math.random(250,450)}}, offer = {type = 'give-item', item = 'flamethrower'}},
    {price = {{"raw-fish", math.random(75,125)}}, offer = {type = 'give-item', item = 'rocket-launcher'}},
    {price = {{"raw-fish", math.random(2,4)}}, offer = {type = 'give-item', item = 'piercing-rounds-magazine'}},
    {price = {{"raw-fish", math.random(14,28)}}, offer = {type = 'give-item', item = 'uranium-rounds-magazine'}},
    {price = {{"raw-fish", math.random(9,20)}}, offer = {type = 'give-item', item = 'piercing-shotgun-shell'}},
    {price = {{"raw-fish", math.random(6,12)}}, offer = {type = 'give-item', item = 'flamethrower-ammo'}},
    {price = {{"raw-fish", math.random(10,20)}}, offer = {type = 'give-item', item = 'rocket'}},
    {price = {{"raw-fish", math.random(15,25)}}, offer = {type = 'give-item', item = 'explosive-rocket'}},
    {price = {{"raw-fish", math.random(15,30)}}, offer = {type = 'give-item', item = 'explosive-cannon-shell'}},
    {price = {{"raw-fish", math.random(25,45)}}, offer = {type = 'give-item', item = 'explosive-uranium-cannon-shell'}},
    {price = {{"raw-fish", math.random(20,40)}}, offer = {type = 'give-item', item = 'cluster-grenade'}},
	{price = {{"raw-fish", math.random(1,3)}}, offer = {type = 'give-item', item = 'land-mine'}},
    {price = {{"raw-fish", math.random(250,500)}}, offer = {type = 'give-item', item = 'modular-armor'}},
    {price = {{"raw-fish", math.random(1500,3000)}}, offer = {type = 'give-item', item = 'power-armor'}},
	{price = {{"raw-fish", math.random(20000,25000)}}, offer = {type = 'give-item', item = 'power-armor-mk2'}},
    {price = {{"raw-fish", math.random(4500,9000)}}, offer = {type = 'give-item', item = 'fusion-reactor-equipment'}},
    {price = {{"raw-fish", math.random(50,100)}}, offer = {type = 'give-item', item = 'battery-equipment'}},
    {price = {{"raw-fish", math.random(700,1100)}}, offer = {type = 'give-item', item = 'battery-mk2-equipment'}},
    {price = {{"raw-fish", math.random(400,700)}}, offer = {type = 'give-item', item = 'belt-immunity-equipment'}},
    {price = {{"raw-fish", math.random(12000,16000)}}, offer = {type = 'give-item', item = 'night-vision-equipment'}},
    {price = {{"raw-fish", math.random(300,500)}}, offer = {type = 'give-item', item = 'exoskeleton-equipment'}},
    {price = {{"raw-fish", math.random(350,500)}}, offer = {type = 'give-item', item = 'personal-roboport-equipment'}},
    {price = {{"raw-fish", math.random(25,50)}}, offer = {type = 'give-item', item = 'construction-robot'}},
    {price = {{"raw-fish", math.random(250,450)}}, offer = {type = 'give-item', item = 'energy-shield-equipment'}},
    {price = {{"raw-fish", math.random(350,550)}}, offer = {type = 'give-item', item = 'personal-laser-defense-equipment'}},
    {price = {{"raw-fish", math.random(125,250)}}, offer = {type = 'give-item', item = 'railgun'}},
    {price = {{"raw-fish", math.random(2,4)}}, offer = {type = 'give-item', item = 'railgun-dart'}},
	{price = {{"raw-fish", math.random(100,175)}}, offer = {type = 'give-item', item = 'loader'}},
	{price = {{"raw-fish", math.random(200,350)}}, offer = {type = 'give-item', item = 'fast-loader'}},
	{price = {{"raw-fish", math.random(400,600)}}, offer = {type = 'give-item', item = 'express-loader'}}
	}
	local surface = game.surfaces[1]
	local market = surface.create_entity {name = "market", position = pos}
	market.destructible = false
	local market_items_to_add = math.random(8,12)
	while market_items_to_add >= 0 do
		local i = math.random(1,#secret_market_items)
		if secret_market_items[i] then
			market.add_market_item(secret_market_items[i])
			market_items_to_add = market_items_to_add - 1
			secret_market_items[i] = nil
		end
	end
end

local function on_chunk_generated(event)
	if not global.noise_seed then global.noise_seed = math.random(1,5000000) end
	local surface = game.surfaces[1]
	local noise = {}
	local tiles = {}
	local enemy_building_positions = {}
	local enemy_worm_positions = {}
	local rock_positions = {}
	local fish_positions = {}
	local treasure_chest_positions = {}
	local secret_shop_locations = {}
	local extra_tree_positions = {}
	local tile_to_insert = false
	local entity_has_been_placed = false
	local pos_x = 0
	local pos_y = 0
	local tile_distance_to_center = 0
	local entities = surface.find_entities(event.area)
	for _, e in pairs(entities) do
		if e.type == "resource" or e.type == "tree" or e.force.name == "enemy" then
			e.destroy()
		end
	end
	local noise_seed_add = 25000
	local current_noise_seed_add = noise_seed_add
	local m1 = 0.12
	local m2 = 0.10
	local m3 = 0.07

	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			pos_x = event.area.left_top.x + x
			pos_y = event.area.left_top.y + y
			tile_distance_to_center = pos_x^2 + pos_y^2

			noise[1] = simplex_noise.d2(pos_x/350, pos_y/350,global.noise_seed+current_noise_seed_add)
			current_noise_seed_add = current_noise_seed_add + noise_seed_add
			noise[2] = simplex_noise.d2(pos_x/200, pos_y/200,global.noise_seed+current_noise_seed_add)
			current_noise_seed_add = current_noise_seed_add + noise_seed_add
			noise[3] = simplex_noise.d2(pos_x/50, pos_y/50,global.noise_seed+current_noise_seed_add)
			current_noise_seed_add = current_noise_seed_add + noise_seed_add
			noise[4] = simplex_noise.d2(pos_x/20, pos_y/20,global.noise_seed+current_noise_seed_add)
			current_noise_seed_add = current_noise_seed_add + noise_seed_add
			local cave_noise = noise[1] + noise[2]*0.3 + noise[3]*0.1 + noise[4]*0.02

			noise[1] = simplex_noise.d2(pos_x/120, pos_y/120,global.noise_seed+current_noise_seed_add)
			current_noise_seed_add = current_noise_seed_add + noise_seed_add
			noise[2] = simplex_noise.d2(pos_x/60, pos_y/60,global.noise_seed+current_noise_seed_add)
			current_noise_seed_add = current_noise_seed_add + noise_seed_add
			noise[3] = simplex_noise.d2(pos_x/40, pos_y/40,global.noise_seed+current_noise_seed_add)
			current_noise_seed_add = current_noise_seed_add + noise_seed_add
			noise[4] = simplex_noise.d2(pos_x/20, pos_y/20,global.noise_seed+current_noise_seed_add)
			current_noise_seed_add = current_noise_seed_add + noise_seed_add
			local cave_noise_2 = noise[1] + noise[2]*0.4 + noise[3]*0.25 + noise[4]*0.1

			noise[1] = simplex_noise.d2(pos_x/50, pos_y/50,global.noise_seed+current_noise_seed_add)
			current_noise_seed_add = current_noise_seed_add + noise_seed_add
			noise[2] = simplex_noise.d2(pos_x/30, pos_y/30,global.noise_seed+current_noise_seed_add)
			current_noise_seed_add = current_noise_seed_add + noise_seed_add
			noise[3] = simplex_noise.d2(pos_x/20, pos_y/20,global.noise_seed+current_noise_seed_add)
			current_noise_seed_add = current_noise_seed_add + noise_seed_add
			noise[4] = simplex_noise.d2(pos_x/10, pos_y/10,global.noise_seed+current_noise_seed_add)
			current_noise_seed_add = current_noise_seed_add + noise_seed_add
			local cave_noise_3 = noise[1] + noise[2]*0.5 + noise[3]*0.25 + noise[4]*0.1

			current_noise_seed_add = noise_seed_add

			tile_to_insert = false
			if tile_distance_to_center > global.spawn_dome_size then

				if tile_distance_to_center > (global.spawn_dome_size + 5000) * (cave_noise_3 * 0.05 + 1.1) then
					if cave_noise > 1 then
						tile_to_insert = "deepwater"
						table.insert(fish_positions, {pos_x,pos_y})
					else
						if cave_noise > 0.98 then
							tile_to_insert = "water"
						else
							if cave_noise > 0.82 then
								tile_to_insert = "grass-1"
								table.insert(enemy_building_positions, {pos_x,pos_y})
								--tile_to_insert = "grass-4"
								--if cave_noise > 0.88 then tile_to_insert = "grass-2" end
								if cave_noise > 0.94 then
									table.insert(extra_tree_positions, {pos_x,pos_y})
									table.insert(secret_shop_locations, {pos_x,pos_y})
								end
							else
								if cave_noise > 0.72 then
									tile_to_insert = "dirt-6"
									if cave_noise < 0.79 then table.insert(rock_positions, {pos_x,pos_y}) end
								end
							end
						end
					end
				end

				if tile_to_insert == false then
					if cave_noise < m1 and cave_noise > m1*-1 then
						tile_to_insert = "dirt-7"
						table.insert(enemy_worm_positions, {pos_x,pos_y})
						if cave_noise_2 > 0.85 and tile_distance_to_center > global.spawn_dome_size + 40000 then
							if math.random(1,48) == 1 then
								local p = surface.find_non_colliding_position("crude-oil",{pos_x,pos_y}, 5,1)
								local e = surface.create_entity {name="crude-oil", position={pos_x,pos_y}, amount=math.floor(math.random(25000+tile_distance_to_center*0.5,50000+tile_distance_to_center),0)}
							end
						end
					else
						if cave_noise_2 < m2 and cave_noise_2 > m2*-1 and cave_noise > (m2*-1) - 0.3 then
							tile_to_insert = "dirt-4"
							table.insert(treasure_chest_positions, {pos_x,pos_y})
						else
							if cave_noise_3 < m3 and cave_noise_3 > m3*-1 and cave_noise_2 < m2+0.3 and cave_noise_2 > (m2*-1)-0.3 then
								tile_to_insert = "dirt-2"
								table.insert(treasure_chest_positions, {pos_x,pos_y})
							end
						end
					end
				end

				if tile_distance_to_center < global.spawn_dome_size * (cave_noise_3 * 0.05 + 1.1)  then
					tile_to_insert = "dirt-7"
				end
			else
				if tile_distance_to_center < 750 * (1 + cave_noise_3 * 0.8) then
					tile_to_insert = "water"
					table.insert(fish_positions, {pos_x,pos_y})
				else
					tile_to_insert = "grass-1"
				end
			end

			if tile_distance_to_center < global.spawn_dome_size and tile_distance_to_center > global.spawn_dome_size - 500 and tile_to_insert == "grass-1" then
				table.insert(rock_positions, {pos_x,pos_y})
			end
			if tile_to_insert == "dirt-7" or tile_to_insert == "dirt-4" or tile_to_insert == "dirt-2" then
				 table.insert(rock_positions, {pos_x,pos_y})
			end

			if tile_to_insert == false then
				table.insert(tiles, {name = "out-of-map", position = {pos_x,pos_y}})
			else
				table.insert(tiles, {name = tile_to_insert, position = {pos_x,pos_y}})
			end
		end
	end
	surface.set_tiles(tiles,true)

	for _, p in pairs(treasure_chest_positions) do
		if math.random(1,200)==1 then
			treasure_chest(p)
		end
	end

	for _, p in pairs(enemy_building_positions) do
		if math.random(1,50)==1 then
			local pos = surface.find_non_colliding_position("biter-spawner", p, 16, 1)
			if pos then
				if math.random(1,3) == 1 then
					surface.create_entity {name="spitter-spawner",position=pos}
				else
					surface.create_entity {name="biter-spawner",position=pos}
				end
			end
		end
	end

	for _, p in pairs(enemy_worm_positions) do
		if math.random(1,300)==1 then
			local tile_distance_to_center = math.sqrt(p[1]^2 + p[2]^2)
			if tile_distance_to_center > global.worm_free_zone_radius then
				local raffle_index = math.ceil((tile_distance_to_center-global.worm_free_zone_radius)*0.01, 0)
				if raffle_index < 1 then raffle_index = 1 end
				if raffle_index > 10 then raffle_index = 10 end
				local entity_name = global.worm_raffle_table[raffle_index][math.random(1,#global.worm_raffle_table[raffle_index])]
				surface.create_entity {name=entity_name, position=p}
			end
		end
	end

	for _, p in pairs(fish_positions) do
		if math.random(1,16)==1 then
			if surface.can_place_entity({name="fish",position=p}) then
				surface.create_entity {name="fish",position=p}
			end
		end
	end

	for _, p in pairs(secret_shop_locations) do
		if math.random(1,10)==1 then
			if surface.count_entities_filtered{area={{p[1]-125,p[2]-125},{p[1]+125,p[2]+125}}, name="market", limit=1} == 0 then
				secret_shop(p)
			end
		end
	end

	for _, p in pairs(extra_tree_positions) do
		if math.random(1,20)==1 then
			surface.create_entity {name="tree-02",position=p}
		end
	end

	for _, p in pairs(rock_positions) do
		if math.random(1,3) ~= 1 then
			surface.create_entity {name=global.rock_raffle[math.random(1,#global.rock_raffle)], position=p}
		end
	end

	local decorative_names = {}
	for k,v in pairs(game.decorative_prototypes) do
		if v.autoplace_specification then
		  decorative_names[#decorative_names+1] = k
		end
	 end
	surface.regenerate_decorative(decorative_names, {{x=math.floor(event.area.left_top.x/32),y=math.floor(event.area.left_top.y/32)}})
end

local function hunger_update(player, food_value)

	local past_hunger = global.player_hunger[player.name]
	global.player_hunger[player.name] = global.player_hunger[player.name] + food_value
	if global.player_hunger[player.name] > 200 then global.player_hunger[player.name] = 200 end

	if past_hunger == 200 and global.player_hunger[player.name] + food_value > 200 then
		global.player_hunger[player.name] = global.player_hunger_spawn_value
		player.character.die("player")
		local t = {" ate too much and exploded.", " should have gone on a diet.", " needs to work on their bad eating habbits.", " should have skipped dinner today."}
		game.print(player.name .. t[math.random(1,#t)], { r=0.75, g=0.0, b=0.0})
	end

	if global.player_hunger[player.name] < 1 then
		global.player_hunger[player.name] = global.player_hunger_spawn_value
		player.character.die("player")
		local t = {" ran out of foodstamps.", " starved.", " should not have skipped breakfast today."}
		game.print(player.name .. t[math.random(1,#t)], { r=0.75, g=0.0, b=0.0})
	end

	if player.character then
		if global.player_hunger_stages[global.player_hunger[player.name]] ~= global.player_hunger_stages[past_hunger] then
			local print_message = "You are feeling " .. global.player_hunger_stages[global.player_hunger[player.name]] .. "."
			if global.player_hunger_stages[global.player_hunger[player.name]] == "Obese" then
				print_message = "You have become " .. global.player_hunger_stages[global.player_hunger[player.name]]  .. "."
			end
			if global.player_hunger_stages[global.player_hunger[player.name]] == "Starving" then
				print_message = "You are starving!"
			end
			player.print(print_message, global.player_hunger_color_list[global.player_hunger[player.name]])
		end
	end

	player.character.character_running_speed_modifier = global.player_hunger_buff[global.player_hunger[player.name]]
	player.character.character_mining_speed_modifier  = global.player_hunger_buff[global.player_hunger[player.name]]
end

local function on_player_joined_game(event)
	local surface = game.surfaces[1]
	local player = Game.get_player_by_index(event.player_index)
	if not global.cave_miner_init_done then
		local p = surface.find_non_colliding_position("player", {0,-40}, 10, 1)
		game.forces["player"].set_spawn_position(p,surface)
		player.teleport(p)
		surface.daytime = 0.5
		surface.freeze_daytime = 1
		game.forces["player"].technologies["landfill"].enabled = false
		game.forces["player"].technologies["night-vision-equipment"].enabled = false
		game.map_settings.enemy_evolution.destroy_factor = 0.004

		global.spawn_dome_size = 20000

		global.player_hunger_fish_food_value = 10
		global.player_hunger_spawn_value = 80
		global.player_hunger = {}
		global.player_hunger_stages = {}
		for x = 1, 200, 1 do
			if x <= 200 then global.player_hunger_stages[x] = "Obese" end
			if x <= 179 then global.player_hunger_stages[x] = "Stuffed" end
			if x <= 150 then global.player_hunger_stages[x] = "Bloated" end
			if x <= 130 then global.player_hunger_stages[x] = "Sated" end
			if x <= 110 then global.player_hunger_stages[x] = "Well fed" end
			if x <= 89 then global.player_hunger_stages[x] = "Fed" end
			if x <= 70 then global.player_hunger_stages[x] = "Hungry" end
			if x <= 35 then global.player_hunger_stages[x] = "Starving" end
		end

		global.player_hunger_color_list = {}
		for x = 1, 50, 1 do
			global.player_hunger_color_list[x] = 		{r = 0.5 + x*0.01, g = x*0.01, b = x*0.005}
			global.player_hunger_color_list[50+x] = {r = 1 - x*0.02, g = 0.5 + x*0.01, b = 0.25}
			global.player_hunger_color_list[100+x] = {r = 0 + x*0.02, g = 1 - x*0.01, b = 0.25}
			global.player_hunger_color_list[150+x] = {r = 1 - x*0.01, g = 0.5 - x*0.01, b = 0.25 - x*0.005}
		end

		global.player_hunger_buff = {}
		local buff_top_value = 0.35
		for x = 1, 200, 1 do
			global.player_hunger_buff[x] = buff_top_value
		end
		local y = 1
		for x = 89, 1, -1 do
			global.player_hunger_buff[x] = buff_top_value - y * 0.01
			y = y + 1
		end
		local y = 1
		for x = 111, 200, 1 do
			global.player_hunger_buff[x] = buff_top_value - y * 0.01
			y = y + 1
		end

		global.rock_inhabitants = {}
		global.rock_inhabitants[1] = {"small-biter"}
		global.rock_inhabitants[2] = {"small-biter","small-biter","small-biter","small-biter","small-biter","medium-biter"}
		global.rock_inhabitants[3] = {"small-biter","small-biter","small-biter","small-biter","medium-biter","medium-biter"}
		global.rock_inhabitants[4] = {"small-biter","small-biter","small-biter","medium-biter","medium-biter","small-spitter"}
		global.rock_inhabitants[5] = {"small-biter","small-biter","medium-biter","medium-biter","medium-biter","small-spitter"}
		global.rock_inhabitants[6] = {"small-biter","small-biter","medium-biter","medium-biter","big-biter","small-spitter"}
		global.rock_inhabitants[7] = {"small-biter","small-biter","medium-biter","medium-biter","big-biter","medium-spitter"}
		global.rock_inhabitants[8] = {"small-biter","medium-biter","medium-biter","medium-biter","big-biter","medium-spitter"}
		global.rock_inhabitants[9] = {"small-biter","medium-biter","medium-biter","big-biter","big-biter","medium-spitter"}
		global.rock_inhabitants[10] = {"medium-biter","medium-biter","medium-biter","big-biter","big-biter","big-spitter"}
		global.rock_inhabitants[11] = {"medium-biter","medium-biter","big-biter","big-biter","big-biter","big-spitter"}
		global.rock_inhabitants[12] = {"medium-biter","big-biter","big-biter","big-biter","big-biter","big-spitter"}
		global.rock_inhabitants[13] = {"big-biter","big-biter","big-biter","big-biter","big-biter","big-spitter"}
		global.rock_inhabitants[14] = {"big-biter","big-biter","big-biter","big-biter","behemoth-biter","big-spitter"}
		global.rock_inhabitants[15] = {"big-biter","big-biter","big-biter","behemoth-biter","behemoth-biter","big-spitter"}
		global.rock_inhabitants[16] = {"big-biter","big-biter","big-biter","behemoth-biter","behemoth-biter","behemoth-spitter"}
		global.rock_inhabitants[17] = {"big-biter","big-biter","behemoth-biter","behemoth-biter","behemoth-biter","behemoth-spitter"}
		global.rock_inhabitants[18] = {"big-biter","behemoth-biter","behemoth-biter","behemoth-biter","behemoth-biter","behemoth-spitter"}
		global.rock_inhabitants[19] = {"behemoth-biter","behemoth-biter","behemoth-biter","behemoth-biter","behemoth-biter","behemoth-spitter"}
		global.rock_inhabitants[20] = {"behemoth-biter","behemoth-biter","behemoth-biter","behemoth-biter","behemoth-spitter","behemoth-spitter"}

		global.rock_raffle = {"sand-rock-big","sand-rock-big","rock-big","rock-big","rock-big","rock-huge"}

		global.worm_raffle_table = {}
		global.worm_raffle_table[1] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret"}
		global.worm_raffle_table[2] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret"}
		global.worm_raffle_table[3] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret"}
		global.worm_raffle_table[4] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret"}
		global.worm_raffle_table[5] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret"}
		global.worm_raffle_table[6] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret"}
		global.worm_raffle_table[7] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret"}
		global.worm_raffle_table[8] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret"}
		global.worm_raffle_table[9] = {"small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret", "big-worm-turret"}
		global.worm_raffle_table[10] = {"small-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret", "big-worm-turret", "big-worm-turret"}
		global.worm_free_zone_radius = math.sqrt(global.spawn_dome_size) + 40

		global.biter_spawn_schedule = {}

		global.treasure_chest_raffle_table = {}
		global.treasure_chest_loot_weights = {}
		table.insert(global.treasure_chest_loot_weights, {{name = 'iron-gear-wheel', count = 32},10})
		table.insert(global.treasure_chest_loot_weights, {{name = 'coal', count = 3},8})
		table.insert(global.treasure_chest_loot_weights, {{name = 'copper-cable', count = 128},10})
		table.insert(global.treasure_chest_loot_weights, {{name = 'inserter', count = 16},4})
		table.insert(global.treasure_chest_loot_weights, {{name = 'fast-inserter', count = 7},3})
		table.insert(global.treasure_chest_loot_weights, {{name = 'stack-filter-inserter', count = 2},1})
		table.insert(global.treasure_chest_loot_weights, {{name = 'stack-inserter', count = 2},1})
		table.insert(global.treasure_chest_loot_weights, {{name = 'burner-inserter', count = 16},6})
		table.insert(global.treasure_chest_loot_weights, {{name = 'electric-engine-unit', count = 11},3})
		table.insert(global.treasure_chest_loot_weights, {{name = 'rocket-fuel', count = 1},3})
		table.insert(global.treasure_chest_loot_weights, {{name = 'empty-barrel', count = 3},7})
		table.insert(global.treasure_chest_loot_weights, {{name = 'lubricant-barrel', count = 1},3})
		table.insert(global.treasure_chest_loot_weights, {{name = 'crude-oil-barrel', count = 4},3})
		table.insert(global.treasure_chest_loot_weights, {{name = 'iron-stick', count = 3},8})
		table.insert(global.treasure_chest_loot_weights, {{name = "small-electric-pole", count = 13},9})
		table.insert(global.treasure_chest_loot_weights, {{name = "firearm-magazine", count = 32},8})
		table.insert(global.treasure_chest_loot_weights, {{name = 'grenade', count = 8},5})
		table.insert(global.treasure_chest_loot_weights, {{name = 'land-mine', count = 15},4})
		table.insert(global.treasure_chest_loot_weights, {{name = 'light-armor', count = 1},1})
		table.insert(global.treasure_chest_loot_weights, {{name = 'heavy-armor', count = 1},2})
		table.insert(global.treasure_chest_loot_weights, {{name = 'pipe', count = 26},6})
		table.insert(global.treasure_chest_loot_weights, {{name = 'wooden-chest', count = 1},3})
		table.insert(global.treasure_chest_loot_weights, {{name = 'burner-mining-drill', count = 1},1})
		table.insert(global.treasure_chest_loot_weights, {{name = 'iron-axe', count = 1},2})
		table.insert(global.treasure_chest_loot_weights, {{name = 'steel-axe', count = 1},3})
		table.insert(global.treasure_chest_loot_weights, {{name = 'raw-wood', count = 24},5})
		table.insert(global.treasure_chest_loot_weights, {{name = 'sulfur', count = 27},7})
		table.insert(global.treasure_chest_loot_weights, {{name = 'explosives', count = 36},6})
		table.insert(global.treasure_chest_loot_weights, {{name = 'shotgun', count = 1},2})
		table.insert(global.treasure_chest_loot_weights, {{name = 'stone-brick', count = 72},4})
		table.insert(global.treasure_chest_loot_weights, {{name = 'small-lamp', count = 4},4})
		table.insert(global.treasure_chest_loot_weights, {{name = 'rail', count = 57},4})
		table.insert(global.treasure_chest_loot_weights, {{name = 'coin', count = 1},1})
		table.insert(global.treasure_chest_loot_weights, {{name = 'assembling-machine-1', count = 1},2})
		table.insert(global.treasure_chest_loot_weights, {{name = 'assembling-machine-2', count = 1},2})
		table.insert(global.treasure_chest_loot_weights, {{name = 'assembling-machine-3', count = 1},1})

		for _, t in pairs (global.treasure_chest_loot_weights) do
			for x = 1, t[2], 1 do
				table.insert(global.treasure_chest_raffle_table, t[1])
			end
		end

		global.ore_spill_cap = 35
		global.stats_rocks_brocken = 0
		global.stats_ores_found = 0
		global.total_ores_mined = 0

		global.rock_mining_chance_weights = {}
		global.rock_mining_chance_weights[1] = {"iron-ore",25}
		global.rock_mining_chance_weights[2] = {"copper-ore",18}
		global.rock_mining_chance_weights[3] = {"coal",14}
		--global.rock_mining_chance_weights[4] = {"stone",8}
		global.rock_mining_chance_weights[4] = {"uranium-ore",3}
		global.rock_mining_raffle_table = {}
		for _, t in pairs (global.rock_mining_chance_weights) do
			for x = 1, t[2], 1 do
				table.insert(global.rock_mining_raffle_table, t[1])
			end
		end

		global.darkness_threat_level = {}
		global.darkness_messages = {
		"Something is lurking in the dark...",
		"A shadow moves. I doubt it is friendly...",
		"The silence grows louder...",
		"Trust not your eyes. They are useless in the dark.",
		"The darkness hides only death. Turn back now.",
		"You hear noises...",
		"They chitter as if laughing, hungry for their next foolish meal...",
		"Despite what the radars tell you, it is not safe here...",
		"The shadows are moving...",
		"You feel like, something is watching you...",
		}

		global.cave_miner_init_done = true
	end
	if player.online_time < 10 then
		create_cave_miner_button(player)
		global.player_hunger[player.name] = global.player_hunger_spawn_value
		hunger_update(player, 0)
		global.darkness_threat_level[player.name] = 0
		player.insert {name = 'pistol', count = 1}
		--player.insert {name = 'raw-fish', count = 1}
		player.insert {name = 'firearm-magazine', count = 16}
		player.insert {name = 'iron-axe', count = 1}
	end
	create_cave_miner_stats_gui(player)
end

local function spawn_cave_inhabitant(pos)
	if not pos.x then return nil end
	if not pos.y then return nil end
	local tile_distance_to_center = math.sqrt(pos.x^2 + pos.y^2)
	local rock_inhabitants_index = math.ceil((tile_distance_to_center-math.sqrt(global.spawn_dome_size))*0.02, 0)
	if rock_inhabitants_index < 1 then rock_inhabitants_index = 1 end
	if rock_inhabitants_index > 20 then rock_inhabitants_index = 20 end
	local entity_name = global.rock_inhabitants[rock_inhabitants_index][math.random(1,#global.rock_inhabitants[rock_inhabitants_index])]
	local p = game.surfaces[1].find_non_colliding_position(entity_name , pos, 7, 0.5)
	if p then game.surfaces[1].create_entity {name=entity_name, position=p} end
end

local function darkness_events()
	for _, p in pairs (game.connected_players) do
		if global.darkness_threat_level[p.name] > 4 then
			for x = 1, global.darkness_threat_level[p.name], 1 do
				spawn_cave_inhabitant(p.position)
			end
			local biters_found = game.surfaces[1].find_enemy_units(p.position, 12, "player")
			for _, biter in pairs(biters_found) do
				biter.set_command({type=defines.command.attack, target=p.character, distraction=defines.distraction.none})
			end
			p.character.damage(math.random(global.darkness_threat_level[p.name]*2,global.darkness_threat_level[p.name]*3),"enemy")
		end
		if global.darkness_threat_level[p.name] == 2 then
			p.print(global.darkness_messages[math.random(1,#global.darkness_messages)],{ r=0.65, g=0.0, b=0.0})
		end
		global.darkness_threat_level[p.name] = global.darkness_threat_level[p.name] + 1
	end
end

local function darkness_checks()
	for _, p in pairs (game.connected_players) do
		p.character.disable_flashlight()
		local tile_distance_to_center = math.sqrt(p.position.x^2 + p.position.y^2)
		if tile_distance_to_center < math.sqrt(global.spawn_dome_size) then
			global.darkness_threat_level[p.name] = 0
		else
			if p.character.driving == true then
				global.darkness_threat_level[p.name] = 0
			else
				local light_source_entities = game.surfaces[1].find_entities_filtered{area={{p.position.x-12,p.position.y-12},{p.position.x+12,p.position.y+12}}, name="small-lamp"}
				for _, lamp in pairs (light_source_entities) do
					local circuit = lamp.get_or_create_control_behavior()
					if circuit then
						if lamp.energy > 50 and circuit.disabled == false then
							global.darkness_threat_level[p.name] = 0
							break
						end
					else
						if lamp.energy > 50 then
							global.darkness_threat_level[p.name] = 0
							break
						end
					end
				end
			end
		end
	end
end

local function on_tick(event)

		if game.tick % 30 == 0 then
			if global.biter_spawn_schedule then
				for x, b in pairs (global.biter_spawn_schedule) do
					if game.tick > b[1] then
						spawn_cave_inhabitant(b[2])
						global.biter_spawn_schedule[x] = nil
					end
				end
			end
		end

		if game.tick % 240 == 0 then
			darkness_checks()
			darkness_events()
		end

		if game.tick % 3600 == 1800 then
			for _, player in pairs(game.connected_players) do
				if player.afk_time < 18000 then	hunger_update(player, -1) end
			end
			refresh_gui()
		end

		if game.tick == 30 then
			local surface = game.surfaces[1]
			--p = game.forces["player"].get_spawn_position(surface)
			local p = game.surfaces[1].find_non_colliding_position("market",{0,-15},60,0.5)
			local market = surface.create_entity {name = "market", position = p}
			market.destructible = false

			for _, item in pairs(market_items.spawn) do
				market.add_market_item(item)
			end
			surface.regenerate_entity({"tree-01", "tree-02","tree-03","tree-04","tree-05","tree-06","tree-07","tree-08","tree-09","dead-dry-hairy-tree","dead-grey-trunk","dead-tree-desert","dry-hairy-tree","dry-tree","rock-big","rock-huge"})
		end

		if global.map_pregeneration_is_active then
			if game.tick % 600 == 0 then
				local r = 1
				for x = 1,40,1 do
					if game.forces.map_pregen.is_chunk_charted(game.surfaces[1], {x,x}) then r = x end
				end
				game.print("Map chunks are generating... current radius " .. r, { r=0.22, g=0.99, b=0.99})
				if game.forces.map_pregen.is_chunk_charted(game.surfaces[1], {40,40}) then
					game.print("Map generation done!", { r=0.22, g=0.99, b=0.99})

					Game.get_player_by_index(1).force = game.forces["player"]
					global.map_pregeneration_is_active = nil
				end
			end
		end
end

local function on_marked_for_deconstruction(event)
	if event.entity.name == "rock-huge" or event.entity.name == "rock-big" or event.entity.name == "sand-rock-big" then
		event.entity.cancel_deconstruction(Game.get_player_by_index(event.player_index).force.name)
	end
end

local function pre_player_mined_item(event)
	local surface = game.surfaces[1]

	if math.random(1,10) == 1 then
		if event.entity.name == "rock-huge" or event.entity.name == "rock-big" or event.entity.name == "sand-rock-big" then
			for x = 1, math.random(6,10), 1 do
				table.insert(global.biter_spawn_schedule, {game.tick + 30*x, event.entity.position})
			end
		end
	end

	if event.entity.name == "rock-huge" or event.entity.name == "rock-big" or event.entity.name == "sand-rock-big" then
		local player = Game.get_player_by_index(event.player_index)
		local rock_position = {x = event.entity.position.x, y = event.entity.position.y}
		event.entity.destroy()
		local tile_distance_to_center = math.sqrt(rock_position.x^2 + rock_position.y^2)

		if math.random(1,3) == 1 then hunger_update(player, -1) end

		surface.spill_item_stack(player.position,{name = "raw-fish", count = math.random(3,4)},true)
		local bonus_amount = math.ceil((tile_distance_to_center - math.sqrt(global.spawn_dome_size)) * 0.38, 0)
		if bonus_amount < 1 then bonus_amount = 0 end
		local amount = (math.random(45,55) + bonus_amount)*(1+game.forces.player.mining_drill_productivity_bonus)

		amount = math.round(amount, 0)
		amount_of_stone = math.round(amount * 0.1,0)

		global.stats_ores_found = global.stats_ores_found + amount + amount_of_stone

		local mined_loot = global.rock_mining_raffle_table[math.random(1,#global.rock_mining_raffle_table)]
		if amount > global.ore_spill_cap then
			surface.spill_item_stack(rock_position,{name = mined_loot, count = global.ore_spill_cap},true)
			amount = amount - global.ore_spill_cap
			local i = player.insert {name = mined_loot, count = amount}
			amount = amount - i
			if amount > 0 then
				surface.spill_item_stack(rock_position,{name = mined_loot, count = amount},true)
			end
		else
			surface.spill_item_stack(rock_position,{name = mined_loot, count = amount},true)
		end

		if amount_of_stone > global.ore_spill_cap then
			surface.spill_item_stack(rock_position,{name = "stone", count = global.ore_spill_cap},true)
			amount_of_stone = amount_of_stone - global.ore_spill_cap
			local i = player.insert {name = "stone", count = amount_of_stone}
			amount_of_stone = amount_of_stone - i
			if amount_of_stone > 0 then
				surface.spill_item_stack(rock_position,{name = "stone", count = amount_of_stone},true)
			end
		else
			surface.spill_item_stack(rock_position,{name = "stone", count = amount_of_stone},true)
		end

		global.stats_rocks_brocken = global.stats_rocks_brocken + 1
		refresh_gui()

		if math.random(1,100) == 1 and mined_loot ~= "stone" then
			local p = {x = rock_position.x, y = rock_position.y}
			local tile_distance_to_center = p.x^2 + p.y^2
			if	tile_distance_to_center > global.spawn_dome_size + 3000 then
				local radius = 50
				if surface.count_entities_filtered{area={{p.x - radius,p.y - radius},{p.x + radius,p.y + radius}}, type="resource", limit=1} == 0 then
					local size_raffle = {{"huge", 20, 30},{"big", 11, 20},{"", 5, 10},{"", 5, 10},{"tiny", 2, 5},{"tiny", 2, 5},{"tiny", 2, 5}}
					local size = size_raffle[math.random(1,#size_raffle)]
					local ore_prints = {coal = {"dark", "Coal"}, ["iron-ore"] = {"shiny", "Iron"}, ["copper-ore"] = {"glimmering", "Copper"}, ["uranium-ore"] = {"glowing", "Uranium"}}
					player.print("You notice something " .. ore_prints[mined_loot][1] .. " underneath the rubble covered floor. It´s a " .. size[1] .. " vein of " ..  ore_prints[mined_loot][2] .. "!!", { r=0.98, g=0.66, b=0.22})
					tile_distance_to_center = math.sqrt(tile_distance_to_center)
					local ore_entities_placed = 0
					local modifier_raffle = {{0,-1},{-1,0},{0,-1},{0,1}}
					while ore_entities_placed < math.random(size[2],size[3]) do
						local a = math.ceil((math.random(tile_distance_to_center*3, tile_distance_to_center*4)) / 1 + ore_entities_placed * 0.5, 0)
						for x = 1, 150, 1 do
							local m = modifier_raffle[math.random(1,#modifier_raffle)]
							local pos = {x = p.x + m[1], y = p.y + m[2]}
							if surface.can_place_entity({name=mined_loot, position=pos, amount=a}) then
								surface.create_entity {name=mined_loot, position=pos, amount=a}
								p = pos
								break
							end
						end
						ore_entities_placed = ore_entities_placed + 1
					end
				end
			end
		end
	end
end

local function on_player_mined_entity(event)
	if event.entity.name == "rock-huge" or event.entity.name == "rock-big" or event.entity.name == "sand-rock-big" then
		event.buffer.clear()
	end
	if event.entity.name == "fish" then
		if math.random(1,2) == 1 then
			local player = Game.get_player_by_index(event.player_index)
			local health = player.character.health
			player.character.damage(math.random(50,150),"enemy")
			if not player.character then
				game.print(player.name .. " should have kept their hands out of the foggy lake waters.",{ r=0.75, g=0.0, b=0.0} )
			else
				if health > 200 then
					player.print("You got bitten by an angry cave piranha.",{ r=0.75, g=0.0, b=0.0})
				else
					local messages = {"Ouch.. That hurt! Better be careful now.", "Just a fleshwound.", "Better keep those hands to yourself or you might loose them."}
					player.print(messages[math.random(1,#messages)],{ r=0.75, g=0.0, b=0.0})
				end
			end
		end
	end
end

local function on_entity_damaged(event)
	if event.entity.name == "rock-huge" or event.entity.name == "rock-big" or event.entity.name == "sand-rock-big" then
		local rock_is_alive = true
		if event.force.name == "enemy" then
			event.entity.health = event.entity.health + (event.final_damage_amount - 0.05)
			if event.entity.health <= event.final_damage_amount then
				rock_is_alive = false
			end
		end
		if event.entity.health <= 0 then rock_is_alive = false end
		if rock_is_alive == false then
			if event.force.name == "player" then
				if math.random(1,8) == 1 then
					for x = 1, math.random(8,12), 1 do
						table.insert(global.biter_spawn_schedule, {game.tick + 5*x, event.entity.position})
					end
				end
			end
			local p = event.entity.position
			local drop_amount = math.random(10,20)
			event.entity.destroy()
			game.surfaces[1].spill_item_stack(p,{name = "stone", count = drop_amount},true)
			global.stats_rocks_brocken = global.stats_rocks_brocken + 1
			global.stats_ores_found = global.stats_ores_found + drop_amount
			refresh_gui()
		end
	end
end

local function on_player_respawned(event)
	local player = Game.get_player_by_index(event.player_index)
	player.character.disable_flashlight()
	global.player_hunger[player.name] = global.player_hunger_spawn_value
	hunger_update(player, 0)
	refresh_gui()
end

local function on_research_finished(event)
	game.forces.player.manual_mining_speed_modifier = game.forces.player.mining_drill_productivity_bonus * 3
	game.forces.player.character_inventory_slots_bonus = game.forces.player.mining_drill_productivity_bonus * 500
	refresh_gui()
end

local function on_gui_click(event)
	if not (event and event.element and event.element.valid) then return end

	local player = Game.get_player_by_index(event.element.player_index)
	local name = event.element.name
	local frame = player.gui.top["caver_miner_stats_frame"]

	if (name == "caver_miner_stats_toggle_button") and (frame == nil) then
		create_cave_miner_stats_gui(player)
	else
		if (name == "caver_miner_stats_toggle_button") then
			frame.destroy()
		end
	end
end

local function on_player_used_capsule(event)
	if event.item.name == "raw-fish" then
		local player = Game.get_player_by_index(event.player_index)
		hunger_update(player, global.player_hunger_fish_food_value)
		player.play_sound{path="utility/armor_insert", volume_modifier=1}
		refresh_gui()
	end
end

function map_pregen()
	local radius = 1280
	if not game.forces.map_pregen then game.create_force("map_pregen") end
	Game.get_player_by_index(1).force = game.forces["map_pregen"]
	game.forces.map_pregen.chart(game.surfaces[1],{{x = -1 * radius, y = -1 * radius}, {x = radius, y = radius}})
	global.map_pregeneration_is_active = true
end

function test()
	local x = 0
	if x == 1 then
		local surface = game.surfaces[1]
		game.player.cheat_mode=true
		game.speed = 1
		surface.daytime = 1
		game.player.force.research_all_technologies()
		game.forces["enemy"].evolution_factor = 0.2
		local chart = 200
		local surface = game.surfaces[1]
		game.forces["player"].chart(surface, {lefttop = {x = chart*-1, y = chart*-1}, rightbottom = {x = chart, y = chart}})
	end
end


Event.add(defines.events.on_player_used_capsule, on_player_used_capsule)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_pre_player_mined_item, pre_player_mined_item)
Event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
