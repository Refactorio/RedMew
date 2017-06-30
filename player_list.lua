--[[
Hello there! 

This will add a player list with "ranks" to your server.
Oh.. and you can also "poke" a player.

To install, add: require "player_list"
to your scenario control.lua.

---MewMew---

pokemessage = 80% by redlabel


things to do (maybe)
make it sorted by time played
make poke buttons count pokes
make division instead of for loop
--]]

local pokemessages = {"a stick", "a leaf", "a moldy carrot", "a crispy slice of bacon", "a french fry", "a realistic toygun", "a broomstick", "a thirteen inch iron stick", "a mechanical keyboard", "a fly fishing cane", "a selfie stick", "an oversized fidget spinner", "a thumb extender", "a dirty straw", "a green bean", "a banana", "an umbrella", "grandpa's walking stick", "live firework", "a toilet brush", "a fake hand", "an undercooked hotdog", "a slice of yesterday's microwaved pizza", "bubblegum", "a biter leg", "grandma's toothbrush", "charred octopus", "a dollhouse bathtub", "a length of copper wire", "a decommissioned nuke", "a smelly trout", "an unopened can of deodorant", "a stone brick", "a half full barrel of lube", "a half empty barrel of lube", "an unexploded cannon shell", "a blasting programmable speaker", "a not so straight rail", "a mismatched pipe to ground", "a surplus box of landmines", "decommissioned yellow rounds", "an oily pumpjack shaft", "a melted plastic bar in the shape of the virgin mary", "a bottle of watermelon vitamin water", "a slice of watermelon", "a stegosaurus tibia", "a basking musician's clarinet", "a twig", "an undisclosed pokey item", "a childhood trophy everyone else got","a dead starfish","a titanium toothpick", "a nail file","a stamp collection","a bucket of lego","a rolled up carpet","a rolled up WELCOME doormat","Bobby's favorite bone","an empty bottle of cheap vodka","a tattooing needle","a peeled cucumber","a stack of cotton candy","a signed baseball bat","that 5 dollar bill grandma sent for christmas","a stack of overdue phone bills","the 'relax' section of the white pages","a bag of gym clothes which never made it to the washing machine","a handful of peanut butter","a pheasant's feather","a rusty pickaxe","a diamond sword","the bill of rights of a banana republic","one of those giant airport Toblerone's", "a long handed inserter", "a wiimote","an easter chocolate rabbit","a ball of yarn the cat threw up","a slightly expired but perfectly edible cheese sandwich", "conclusive proof of lizard people existence","a pen drive full of high res wallpapers","a pet hamster","an oversized goldfish","a one foot extension cord","a CD from Walmart's 1 dollar bucket","a magic wand","a list of disappointed people who believed in you","murder exhibit no. 3","a paperback copy of 'Great Expectations'", "a baby biter", "a little biter fang", "the latest diet fad","a belt that no longer fits you","an abandoned pet rock","a lava lamp", "some spirit herbs","a box of fish sticks found at the back of the freezer","a bowl of tofu rice", "a bowl of ramen noodles", "a live lobster!", "a miniature golf cart","dunce cap","a fully furnished x-mas tree", "an orphaned power pole"}

local function create_player_list_button(event)	
	local player = game.players[event.player_index]
	if not global.poke_spam_protection then global.poke_spam_protection = {} end
	global.poke_spam_protection[event.player_index] = game.tick
	if not global.player_list_pokes_counter then global.player_list_pokes_counter = {} end	
	
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
	
	local time_needed = 15
	
	local time_counter = time_needed
	for i=1,#ranks,1 do
		if m < time_counter then return ranks[i] end
		time_counter = time_counter + time_needed 
	end

	return ranks[#ranks]
end

local function player_list_show(player)
	
	player.gui.left.direction = "horizontal"	
	local frame = player.gui.left.add { type = "frame", name = "player-list-panel", direction = "vertical" }
	frame.style.top_padding = 8
	frame.style.left_padding = 8
	frame.style.right_padding = 8
	frame.style.bottom_padding = 8
	
	local player_list_panel_table = frame.add { type = "table", name = "player_list_panel_table", colspan = 4 }
	
	local label = player_list_panel_table.add { type = "label", name = "player_list_panel_header_1", caption = "" }
	label.style.font = "default-game"
	label.style.font_color = { r=0.00, g=0.00, b=0.00}
	label.style.minimal_width = 35
	
	local label = player_list_panel_table.add { type = "label", name = "player_list_panel_header_2", caption = "Players online" }
	label.style.font = "default-listbox"
	label.style.font_color = { r=0.98, g=0.66, b=0.22}
	label.style.minimal_width = 140
	
	local label = player_list_panel_table.add { type = "label", name = "player_list_panel_header_3", caption = "Time played" }
	label.style.font = "default-listbox"
	label.style.font_color = { r=0.98, g=0.66, b=0.22}
	label.style.minimal_width = 140
	
	local label = player_list_panel_table.add { type = "label", name = "player_list_panel_header_4", caption = "Poke" }
	label.style.font = "default-bold"
	label.style.font_color = { r=0.98, g=0.66, b=0.22}
	--label.style.minimal_width = 35
	
	
	local x = 1
	local online_players_amount = 0
	--local connected_player_table = {}
	
		while (game.players[x] ~= nil) do
		
			local player = game.players[x]
			if player.connected then
				
				online_players_amount = online_players_amount + 1
				--connected_player_table[online_players_amount] = {t_player_index = x, t_player_playtime = player.online_time}
				local str = get_rank(player)

				player_list_panel_table.add { type = "sprite", name = "player_rank_sprite_" .. x, sprite = str }
				
				local label = player_list_panel_table.add { type = "label", name = "player_list_panel_player_names_" .. x, caption = player.name }		
				label.style.font = "default"				
				label.style.font_color = {
					r = .4 + player.color.r * 0.6,
					g = .4 + player.color.g * 0.6,
					b = .4 + player.color.b * 0.6,
				}
				--label.style.minimal_width = 140
				
				local time_played = get_formatted_playtime(player.online_time)
								
				local label = player_list_panel_table.add { type = "label", name = "player_list_panel_player_time_played_" .. x, caption = time_played }
				
				if not global.player_list_pokes_counter[player.index] then global.player_list_pokes_counter[player.index] = 0 end
				
				local button = player_list_panel_table.add { type = "button", name = "poke_player_" .. player.name, caption = global.player_list_pokes_counter[player.index] }		
				button.style.font = "default"
				label.style.font_color = { r=0.83, g=0.83, b=0.83}
				button.style.minimal_height = 28
				button.style.minimal_width = 28
				button.style.maximal_height = 28
				button.style.maximal_width = 28
				button.style.top_padding = 0
				button.style.left_padding = 0
				button.style.right_padding = 0
				button.style.bottom_padding = 0
								
			end
		x = x + 1
	end
	x = x - 1
	player_list_panel_table.player_list_panel_header_1.caption = "    " .. online_players_amount
	
--[[	
	connected_player_table[2] = {t_player_index = 27, t_player_playtime = 235355}
	connected_player_table[3] = {t_player_index = 7, t_player_playtime = 11532563}
	connected_player_table[4] = {t_player_index = 9, t_player_playtime = 2355}
	connected_player_table[5] = {t_player_index = 15, t_player_playtime = 43545}
	
	--table.sort(connected_player_table, function(a, b) return a[2] > b[2] end)
	
	for x=1,#connected_player_table,1 do
		local z = connected_player_table[x]
		local a = "t_player_index=" ..  z.t_player_index
		a = a.. "    t_player_playtime=" 
		a = a .. z.t_player_playtime
		game.print(a)
	end
--]]	
end

local function on_gui_click(event)
	if not (event and event.element and event.element.valid) then return end
		local player = game.players[event.element.player_index]
		local name = event.element.name
		
		if (name == "player_list_button") then
			local frame = player.gui.left["player-list-panel"]
			if (frame) then
				frame.destroy()
			else
				player_list_show(player)
			end
		end
		
		--Poke other players
	if event.element.type == "button" then
		local x = string.find(name, "poke_player_")
		if x ~= nil then
			local y = string.len(event.element.name)
			local poked_player = string.sub(event.element.name, 13, y)
			if player.name ~= poked_player then
				local x = global.poke_spam_protection[event.element.player_index] + 420
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

local function player_list_refresh()
	if game.tick % 1800 == 0 then
		local x = 1
		while game.players[x] ~= nil do
			local player = game.players[x]
			if player.connected then
				local frame = player.gui.left["player-list-panel"]
				if frame then
					frame.destroy()
					player_list_show(player)
				end
			end
			x = x + 1
		end
	end
end


Event.register(defines.events.on_tick, player_list_refresh)
Event.register(defines.events.on_player_joined_game, create_player_list_button)
Event.register(defines.events.on_player_left_game, player_log_out)
Event.register(defines.events.on_gui_click, on_gui_click)