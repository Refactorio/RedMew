
--[[
Hello there!

This will add a player list with "ranks" to your server.
Oh.. and you can also "poke" a player.
pokemessages = 80% by redlabel

To install, add: require "player_list"
to your scenario control.lua.

---MewMew---


things to do (maybe)
make it sorted by time played
--]]

local symbol_asc = "▲"
local symbol_desc = "▼"

local pokemessages = require "locale.resources.poke_messages"

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if not global.poke_spam_protection then global.poke_spam_protection = {} end
	global.poke_spam_protection[event.player_index] = game.tick
	if not global.player_list_pokes_counter then global.player_list_pokes_counter = {} end

	if not global.scenario.variables.player_deaths[player.name] then global.scenario.variables.player_deaths[player.name] = 0 end
	if not global.fish_market_fish_caught[event.player_index] then global.fish_market_fish_caught[event.player_index] = 0 end
	if not global.fish_market_fish_spent[event.player_index] then global.fish_market_fish_spent[event.player_index] = 0 end

	if player.gui.top.player_list_button == nil then
		local button = player.gui.top.add({ type = "sprite-button", name = "player_list_button", sprite = "item/heavy-armor" })
		button.style.minimal_height = 38
		button.style.minimal_width = 38
		button.style.top_padding = 2
		button.style.left_padding = 4
		button.style.right_padding = 4
		button.style.bottom_padding = 2
	end
end

local function get_formatted_playtime(x)
	local y = x / 216000
	y = tostring(y)
	local h = ""
	for i=1,10,1 do
		local z = string.sub(y, i, i)

		if z == "." then
			break
		else
			h = h .. z
		end
	end

	local m = x % 216000
	m = m / 3600
	m = math.floor(m)
	m = tostring(m)

	if h == "0" then
		local str = m .. " minutes"
		return str
	else
		local str = h .. " hours "
		str = str .. m
		str = str .. " minutes"
		return str
	end
end

local function get_rank(player)
	local m = player.online_time  / 3600

	local ranks = {
	"item/iron-axe","item/burner-mining-drill","item/burner-inserter","item/stone-furnace","item/light-armor","item/steam-engine",
	"item/inserter", "item/transport-belt", "item/underground-belt", "item/splitter","item/assembling-machine-1","item/long-handed-inserter","item/electronic-circuit","item/electric-mining-drill",
	"item/heavy-armor","item/steel-furnace","item/steel-axe","item/gun-turret","item/fast-transport-belt", "item/fast-underground-belt", "item/fast-splitter","item/assembling-machine-2","item/fast-inserter","item/radar","item/filter-inserter",
	"item/defender-capsule","item/pumpjack","item/chemical-plant","item/solar-panel","item/advanced-circuit","item/modular-armor","item/accumulator", "item/construction-robot",
	"item/distractor-capsule","item/stack-inserter","item/electric-furnace","item/express-transport-belt","item/express-underground-belt", "item/express-splitter","item/assembling-machine-3","item/processing-unit","item/power-armor","item/logistic-robot","item/laser-turret",
	"item/stack-filter-inserter","item/destroyer-capsule","item/power-armor-mk2","item/flamethrower-turret","item/beacon",
	"item/steam-turbine","item/centrifuge","item/nuclear-reactor"
	}

	--52 ranks

	local time_needed = 15 -- in minutes between rank upgrades
	m = m / time_needed
	m = math.floor(m)
	m = m + 1

	if m > #ranks then m = #ranks end

	return ranks[m]
end

local function get_sorted_list(sort_by)
	local player_list = {}
	for i, player in pairs(game.connected_players) do
		player_list[i] = {}
		player_list[i].rank = get_rank(player)
		player_list[i].name = player.name
		player_list[i].played_time = get_formatted_playtime(player.online_time)
		player_list[i].played_ticks = player.online_time
		if not global.player_list_pokes_counter[player.index] then global.player_list_pokes_counter[player.index] = 0 end
		player_list[i].pokes = global.player_list_pokes_counter[player.index]
		player_list[i].player_index = player.index
	end

	for i = #player_list, 1, -1 do
		for i2 = #player_list, 1, -1 do
			if sort_by == "pokes_asc" then
				if player_list[i].pokes > player_list[i2].pokes then
					local a = player_list[i]
					local b = player_list[i2]
					player_list[i] = b
					player_list[i2] = a
				end
			end
			if sort_by == "pokes_desc" then
				if player_list[i].pokes < player_list[i2].pokes then
					local a = player_list[i]
					local b = player_list[i2]
					player_list[i] = b
					player_list[i2] = a
				end
			end
			if sort_by == "time_played_asc" then
				if player_list[i].played_ticks > player_list[i2].played_ticks then
					local a = player_list[i]
					local b = player_list[i2]
					player_list[i] = b
					player_list[i2] = a
				end
			end
			if sort_by == "time_played_desc" then
				if player_list[i].played_ticks < player_list[i2].played_ticks then
					local a = player_list[i]
					local b = player_list[i2]
					player_list[i] = b
					player_list[i2] = a
				end
			end
			if sort_by == "distance_asc" then
				if global.scenario.variables.player_walk_distances[player_list[i].name] > global.scenario.variables.player_walk_distances[player_list[i2].name] then
					local a = player_list[i]
					local b = player_list[i2]
					player_list[i] = b
					player_list[i2] = a
				end
			end
			if sort_by == "distance_desc" then
				if global.scenario.variables.player_walk_distances[player_list[i].name] < global.scenario.variables.player_walk_distances[player_list[i2].name] then
					local a = player_list[i]
					local b = player_list[i2]
					player_list[i] = b
					player_list[i2] = a
				end
			end
			if sort_by == "name_asc" then
				if player_list[i].name > player_list[i2].name then
					local a = player_list[i]
					local b = player_list[i2]
					player_list[i] = b
					player_list[i2] = a
				end
			end
			if sort_by == "name_desc" then
				if player_list[i].name < player_list[i2].name then
					local a = player_list[i]
					local b = player_list[i2]
					player_list[i] = b
					player_list[i2] = a
				end
			end
		end
	end
	return player_list
end

local function player_list_show(player, sort_by)

	local frame = player.gui.left["player-list-panel"]
	if frame then frame.destroy() end

	player.gui.left.direction = "horizontal"
	local frame = player.gui.left.add { type = "frame", name = "player-list-panel", direction = "vertical" }
	frame.style.minimal_width = 650
	frame.style.top_padding = 8
	frame.style.left_padding = 8
	frame.style.right_padding = 8
	frame.style.bottom_padding = 8


	local player_list_panel_header_table = frame.add { type = "table", name = "player_list_panel_header_table", colspan = 7 }

	local label = player_list_panel_header_table.add { type = "label", name = "player_list_panel_header_1", caption = "    " .. #game.connected_players }
	label.style.font = "default-game"
	label.style.font_color = { r=0.00, g=0.00, b=0.00}
	label.style.minimal_width = 35

	local str = ""
	if sort_by == "name_asc" then str = symbol_asc .. " " end
	if sort_by == "name_desc" then str = symbol_desc .. " " end
	local label = player_list_panel_header_table.add { type = "label", name = "player_list_panel_header_2", caption = str .. "Players online"  }
	label.style.font = "default-listbox"
	label.style.font_color = { r=0.98, g=0.66, b=0.22}
	label.style.minimal_width = 160
	label.style.maximal_width = 160

	str = ""
	if sort_by == "time_played_asc" then str = symbol_asc .. " " end
	if sort_by == "time_played_desc" then str = symbol_desc .. " " end
	local label = player_list_panel_header_table.add { type = "label", name = "player_list_panel_header_3", caption = str .. "Time played" }
	label.style.font = "default-listbox"
	label.style.font_color = { r=0.98, g=0.66, b=0.22}
	label.style.minimal_width = 130
	label.style.maximal_width = 130


	str = ""
	if sort_by == "distance_asc" then str = symbol_asc .. " " end
	if sort_by == "distance_desc" then str = symbol_desc .. " " end
	local label = player_list_panel_header_table.add { type = "label", name = "player_list_panel_header_4", caption = str .. "Distance walked" }
	label.style.font = "default-listbox"
	label.style.font_color = { r=0.98, g=0.66, b=0.22}
	label.style.minimal_width = 150
	label.style.maximal_width = 150

	str = ""
	if sort_by == "fish_asc" then str = symbol_asc .. " " end
	if sort_by == "fish_desc" then str = symbol_desc .. " " end
	local label = player_list_panel_header_table.add { type = "label", name = "player_list_panel_header_fish", caption = str .. "Fish (Caught/Used)" }
	label.style.font = "default-listbox"
	label.style.font_color = { r=0.98, g=0.66, b=0.22}
	label.style.minimal_width = 150
	label.style.maximal_width = 150

	str = ""
	if sort_by == "deaths_asc" then str = symbol_asc .. " " end
	if sort_by == "deaths_desc" then str = symbol_desc .. " " end
	local label = player_list_panel_header_table.add { type = "label", name = "player_list_panel_header_deaths", caption = str .. "Deaths" }
	label.style.font = "default-listbox"
	label.style.font_color = { r=0.98, g=0.66, b=0.22}
	label.style.minimal_width = 80
	label.style.maximal_width = 80

	str = ""
	if sort_by == "pokes_asc" then str = symbol_asc .. " " end
	if sort_by == "pokes_desc" then str = symbol_desc .. " " end
	local label = player_list_panel_header_table.add { type = "label", name = "player_list_panel_header_5", caption = str .. "Poke" }
	label.style.font = "default-listbox"
	label.style.font_color = { r=0.98, g=0.66, b=0.22}
	label.style.minimal_width = 35

	local player_list_panel_table = frame.add { type = "scroll-pane", name = "scroll_pane", direction = "vertical", horizontal_scroll_policy = "never", vertical_scroll_policy = "auto"}
	player_list_panel_table.style.maximal_height = 650


	player_list_panel_table = player_list_panel_table.add { type = "table", name = "player_list_panel_table", colspan = 7 }

	local player_list = get_sorted_list(sort_by)

	for i = 1, #player_list, 1 do

		local sprite = player_list_panel_table.add { type = "sprite", name = "player_rank_sprite_" .. i, sprite = player_list[i].rank }
		sprite.style.minimal_width = 35

		local label = player_list_panel_table.add { type = "label", name = "player_list_panel_player_names_" .. i, caption = player_list[i].name }
		label.style.font = "default"
		label.style.font_color = {
			r = .4 + game.players[player_list[i].player_index].color.r * 0.6,
			g = .4 + game.players[player_list[i].player_index].color.g * 0.6,
			b = .4 + game.players[player_list[i].player_index].color.b * 0.6,
		}
		label.style.minimal_width = 160
		label.style.maximal_width = 160

		local label = player_list_panel_table.add { type = "label", name = "player_list_panel_player_time_played_" .. i, caption = player_list[i].played_time }
		label.style.minimal_width = 130
		label.style.maximal_width = 130

		local label = player_list_panel_table.add { type = "label", name = "player_list_panel_player_distance_" .. i, caption = round(global.scenario.variables.player_walk_distances[player_list[i].name]/1000, 1) .. " km" }
		label.style.minimal_width = 150
		label.style.maximal_width = 150

		local label = player_list_panel_table.add { type = "label", name = "player_list_panel_player_fish" .. i, caption = global.fish_market_fish_caught[player_list[i].player_index] .. " / " .. global.fish_market_fish_spent[player_list[i].player_index] }
		label.style.minimal_width = 150
		label.style.maximal_width = 150

		local label = player_list_panel_table.add { type = "label", name = "player_list_panel_player_deaths" .. i, caption = global.scenario.variables.player_deaths[player_list[i].name] }
		label.style.minimal_width = 80
		label.style.maximal_width = 80


		local flow = player_list_panel_table.add { type = "flow", name = "button_flow_" .. i, direction = "horizontal" }
		flow.add { type = "label", name = "button_spacer_" .. i, caption = "" }
		local button = flow.add { type = "button", name = "poke_player_" .. player_list[i].name, caption = player_list[i].pokes }
		button.style.font = "default"
		label.style.font_color = { r=0.83, g=0.83, b=0.83}
		button.style.minimal_height = 30
		button.style.minimal_width = 30
		button.style.maximal_height = 30
		button.style.maximal_width = 30
		button.style.top_padding = 0
		button.style.left_padding = 0
		button.style.right_padding = 0
		button.style.bottom_padding = 0
	end
end

local function on_gui_click(event)
	if not (event and event.element and event.element.valid) then return end
		local player = game.players[event.element.player_index]
		local name = event.element.name

		if (name == "player_list_button") then
			if player.gui.left["player-list-panel"] then
				player.gui.left["player-list-panel"].destroy()
			else
				player_list_show(player,"time_played_desc")
			end
		end

		if (name == "player_list_panel_header_2") then
			if string.find(event.element.caption, symbol_desc) then
				player_list_show(player,"name_asc")
			else
				player_list_show(player,"name_desc")
			end
		end
		if (name == "player_list_panel_header_3") then
			if string.find(event.element.caption, symbol_desc) then
				player_list_show(player,"time_played_asc")
			else
				player_list_show(player,"time_played_desc")
			end
		end
		if (name == "player_list_panel_header_4") then
			if string.find(event.element.caption, symbol_desc) then
				player_list_show(player,"distance_asc")
			else
				player_list_show(player,"distance_desc")
			end
		end
		if (name == "player_list_panel_header_5") then
			if string.find(event.element.caption, symbol_desc) then
				player_list_show(player,"pokes_asc")
			else
				player_list_show(player,"pokes_desc")
			end
		end
		--Poke other players
	if event.element.type == "button" then
		local x = string.find(name, "poke_player_")
		if x ~= nil then
			local y = string.len(event.element.name)
			local poked_player = string.sub(event.element.name, 13, y)
			if player.name ~= poked_player then
				local x = global.poke_spam_protection[event.element.player_index] + 240
				if x < game.tick then
					local str = ">> "
					str = str .. player.name
					str = str .. " has poked "
					str = str .. poked_player
					str = str .. " with "
					local z = math.random(1,#pokemessages)
					str = str .. pokemessages[z]
					str = str .. " <<"
					game.print(str)
					global.poke_spam_protection[event.element.player_index] = game.tick
					local p = game.players[poked_player]
					global.player_list_pokes_counter[p.index] = global.player_list_pokes_counter[p.index] + 1
				end
			end
		end
	end

end

function player_list_on_12_seconds()
	for _,player in pairs(game.connected_players) do
		if player.gui.left["player-list-panel"] then
			local sort_method
			if string.find(player.gui.left["player-list-panel"].player_list_panel_header_table.player_list_panel_header_2.caption, symbol_desc) then sort_method = "name_desc" end
			if string.find(player.gui.left["player-list-panel"].player_list_panel_header_table.player_list_panel_header_2.caption, symbol_asc) then sort_method = "name_asc" end
			if string.find(player.gui.left["player-list-panel"].player_list_panel_header_table.player_list_panel_header_3.caption, symbol_desc) then sort_method = "time_played_desc" end
			if string.find(player.gui.left["player-list-panel"].player_list_panel_header_table.player_list_panel_header_3.caption, symbol_asc) then sort_method = "time_played_asc" end
			if string.find(player.gui.left["player-list-panel"].player_list_panel_header_table.player_list_panel_header_4.caption, symbol_desc) then sort_method = "distance_desc" end
			if string.find(player.gui.left["player-list-panel"].player_list_panel_header_table.player_list_panel_header_4.caption, symbol_asc) then sort_method = "distance_asc" end
			if string.find(player.gui.left["player-list-panel"].player_list_panel_header_table.player_list_panel_header_5.caption, symbol_desc) then sort_method = "pokes_desc" end
			if string.find(player.gui.left["player-list-panel"].player_list_panel_header_table.player_list_panel_header_5.caption, symbol_asc) then sort_method = "pokes_asc" end
			player.gui.left["player-list-panel"].destroy()
			player_list_show(player,sort_method)
		end
	end
end

function on_player_died( event_player, cause )
	game.print(serpent.block(event_player))
	player = game.players[event_player.player_index]
	game.print(serpent.block(player))
	game.print(player.name  .. " Died")
	if not global.scenario.variables.player_deaths[player.name] then
		global.scenario.variables.player_deaths[player.name] = 0
	end
	global.scenario.variables.player_deaths[player.name] = global.scenario.variables.player_deaths[player.name] + 1
end


Event.register(defines.events.on_player_joined_game, on_player_joined_game)
Event.register(defines.events.on_gui_click, on_gui_click)
Event.register(defines.events.on_player_died, on_player_died)
