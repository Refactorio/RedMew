--[[
Hello there script explorer! 

With this you can add a "Fish Market" to your World
You can earn fish by killing alot of biters or by mining wood, ores, rocks.
To spawn the market, do "/c market()" in your chat ingame as the games host.
It will spawn a few tiles north of the current position where your character is.

---MewMew---
--]]

function market()
  local radius = 10
  local surface = game.surfaces[1]
  -- clear trees and landfill in start area
  local start_area = {left_top = {-20, -20}, right_bottom = {20, 20}}
  for _, e in pairs(surface.find_entities_filtered{area=start_area, type="tree"}) do
    --e.destroy()
  end
  for i = -radius, radius, 1 do
    for j = -radius, radius, 1 do
      if (surface.get_tile(i,j).collides_with("water-tile")) then
        --surface.set_tiles{{name = "grass", position = {i,j}}}
      end
    end
  end
  
  local player = game.players[1]
 
  local market_location = {x = player.position.x, y = player.position.y}
  market_location.y = market_location.y - 4
  
  -- create water around market
  local waterTiles = {}
  for i = -4, 4 do
    for j = -4, 4 do
        --table.insert(waterTiles, {name = "water-green", position={market_location.x + i, market_location.y + j}})
    end
  end
  surface.set_tiles(waterTiles)
  local market = surface.create_entity{name="market", position=market_location, force=force}
  market.destructible = false

  market.add_market_item{price={{"raw-fish", 1}}, offer={type="give-item", item="rail", count=2}}
  market.add_market_item{price={{"raw-fish", 2}}, offer={type="give-item", item="rail-signal"}}
  market.add_market_item{price={{"raw-fish", 2}}, offer={type="give-item", item="rail-chain-signal"}}
  market.add_market_item{price={{"raw-fish", 15}}, offer={type="give-item", item="train-stop"}}
  market.add_market_item{price={{"raw-fish", 75}}, offer={type="give-item", item="locomotive"}}
  market.add_market_item{price={{"raw-fish", 250}}, offer={type="give-item", item="small-plane"}} 
  market.add_market_item{price={{"raw-fish", 30}}, offer={type="give-item", item="cargo-wagon"}}
  market.add_market_item{price={{"raw-fish", 1}}, offer={type="give-item", item="red-wire", count=2}}
  market.add_market_item{price={{"raw-fish", 1}}, offer={type="give-item", item="green-wire", count=2}}
  market.add_market_item{price={{"raw-fish", 3}}, offer={type="give-item", item="decider-combinator"}}
  market.add_market_item{price={{"raw-fish", 3}}, offer={type="give-item", item="arithmetic-combinator"}}
  market.add_market_item{price={{"raw-fish", 3}}, offer={type="give-item", item="constant-combinator"}}
  market.add_market_item{price={{"raw-fish", 7}}, offer={type="give-item", item="programmable-speaker"}}   
  market.add_market_item{price={{"raw-fish", 3}}, offer={type="give-item", item="piercing-rounds-magazine"}}
  market.add_market_item{price={{"raw-fish", 2}}, offer={type="give-item", item="grenade"}}
  market.add_market_item{price={{"raw-fish", 1}}, offer={type="give-item", item="land-mine"}}
  market.add_market_item{price={{"raw-fish", 1}}, offer={type="give-item", item="solid-fuel"}}
  market.add_market_item{price={{"raw-fish", 125}}, offer={type="give-item", item="rocket-launcher"}}
  market.add_market_item{price={{"raw-fish", 15}}, offer={type="give-item", item="rocket"}}   
  market.add_market_item{price={{"raw-fish", 20}}, offer={type="give-item", item="explosive-rocket"}}  
  market.add_market_item{price={{"raw-fish", 2500}}, offer={type="give-item", item="atomic-bomb"}} 
  market.add_market_item{price={{"raw-fish", 1000}}, offer={type="give-item", item="belt-immunity-equipment"}} 
  
end

local function create_market_init_button(event)
	local player = game.players[1]
	
	if player.gui.top.poll == nil then
		local button = player.gui.top.add { name = "poll", type = "sprite-button", sprite = "item/programmable-speaker" }
		button.style.font = "default-bold"
		button.style.minimal_height = 38
		button.style.minimal_width = 38
		button.style.top_padding = 2
		button.style.left_padding = 4
		button.style.right_padding = 4
		button.style.bottom_padding = 2
	end
end

local fish_market_message = {}

local fish_market_bonus_message = {"Why don’t fish like basketball? Cause they’re afraid of the net", "What do you get when you cross a banker with a fish? A Loan shark!", "How do you make an Octupus laugh? With ten-tickles", "What do you call a fish that needs help with his or her vocals? Autotuna", "What is the difference between a piano and a fish? You can tune a piano but you cannot tuna fish.", "What did the blind man say when he passed the fish market? Good morning ladies.", "Did you hear about the goldfish who went bankrupt? Now he’s a bronze fish.", "What happens when you put nutella on salmon? You get salmonella", "What do you call a fish with no eyes?…Fsh", "What kind of money do fishermen make?…Net profits", "What do you get if you cross a salmon, a bird’s leg and a hand?…Birdsthigh fish fingers", "Why is a fish easy to weigh?…Because it has its own scales", "Why are gold fish orange?…The water makes them rusty", "What was the Tsar of Russia’s favorite fish?…Tsardines", "Why did the dog jump into the sea?…He wanted to chase the catfish", "Which fish dresses the best?…The Swordfish – It always looks sharp", "What do you get if you cross an abbot with a trout?…Monkfish", "What do you call a big fish who makes you an offer you can’t refuse?…The Codfather", "Why is a swordfish’s nose 11 inches long?…If it were 12 inches long it would be a foot", "What do you get if you cross a trout with an apartment?…A flat fish", "Why are fish no good at tennis?…They don’t like to get too close to the net", "How do the fish get to school?…By octobus", "What fish make the best sandwich?…A peanut butter and jellyfish", "Man: Can I have a fly rod and reel for my son?…Fishing Shop Owner: Sorry sir we don’t do trades", "Where do fish keep their money?…In the river bank", "Why do fish like arcade games?…Because they are finball wizards", "What is a mermaid?…A deep-she fish", "What do you get if you cross a whale with rotten fish?…Moby Sick", "Why didn’t the lobster share his toys?…He was too shellfish", "What do fish use to make telephone calls?…a Shell phone", "Why don’t fish make very good tennis balls?…They keep getting caught in the net", "Electric eels and electric rays have enough electricity to kill a horse.", "Most fish have taste buds all over their body.", "Most brands of lipstick contain fish scales.", "A fish does not add new scales as it grows, but the scales it has increase in size. In this way, growth rings are formed and the rings reveal the age of a fish.", "An inflated porcupine fish can reach a diameter of up to 35 inches. It puffs up by swallowing water and then storing it in its stomach.", "Most fish cannot swim backwards. Those that can are mainly members of one of the eel families.", "The fastest fish is the sailfish. It can swim as fast as a car travels on the highway.","Some desert pupfish can live in hot springs that reach temperatures greater than 113° F.","Anableps, four-eyed fish, can see above and below water at the same time.","Catfish have over 27,000 taste buds. Humans have around 7,000.","One hagfish can make enough slime in one minute to fill a bucket.","A female sunfish can lay 300 million eggs each year.", "Fish feel pain and suffer stress just like mammals and birds.", "The Dwarf Seahorse is so slow you can’t see it move", "Some fish are as small as a grain of rice", "There's a species of fish called 'Slippery Dick'", "Herrings communicate through farts.", "One Puffer Fish contains enough poison to kill 30 medium-biters.", "When Anglerfish mate, they melt into each other and share their bodies forever.", "A koi fish named 'Hanako' lived for 225 years."}

local total_fish_market_messages = #fish_market_message
local total_fish_market_bonus_messages = #fish_market_bonus_message

if not global.fish_market_fish_caught then global.fish_market_fish_caught = {} end

local function fish_earned(event, amount)

	local player = game.players[event.player_index]
	player.insert { name = "raw-fish", count = amount }
	
	if global.fish_market_fish_caught[event.player_index] then
		global.fish_market_fish_caught[event.player_index] = global.fish_market_fish_caught[event.player_index] + 1
	else
		global.fish_market_fish_caught[event.player_index] = 1
	end
	
	if global.fish_market_fish_caught[event.player_index] <= total_fish_market_messages then
		local x = global.fish_market_fish_caught[event.player_index]
		player.print(fish_market_message[x])
	end		
	
	local x = global.fish_market_fish_caught[event.player_index] % 7
	if x == 0 then
		local z = math.random(1,total_fish_market_bonus_messages)
		player.print(fish_market_bonus_message[z])
	end			

end

local function preplayer_mined_item(event)

--	game.print(event.entity.name)
--	game.print(event.entity.type)

	if event.entity.type == "resource" then
		local x = math.random(1,2)		
		if x == 1 then		
			fish_earned(event, 1)
		end		
	end
	
	if event.entity.name == "fish" then			
			fish_earned(event, 0)	
	end
	
	if event.entity.name == "stone-rock" then			
			fish_earned(event, 10)	
	end
	
	if event.entity.name == "huge-rock" then			
			fish_earned(event, 25)	
	end
	
	if event.entity.name == "big-rock" then			
			fish_earned(event, 15)	
	end

	if event.entity.type == "tree" then
		local x = math.random(1,4)
		if x == 1 then		
			fish_earned(event, 4)
		end
	end
end

local function fish_drop_entity_died(event)
	
	if event.entity.force.name == "enemy" then
--		global.score_biter_total_kills = global.score_biter_total_kills + 1
--		game.print(global.score_biter_total_kills)
		if global.score_biter_total_kills % 30 == 0 then
			local surface = event.entity.surface
			local x = math.random(1,3)
			surface.spill_item_stack(event.entity.position, { name = "raw-fish", count = x }, 1)
		end
	end		
end


Event.register(defines.events.on_preplayer_mined_item, preplayer_mined_item)
Event.register(defines.events.on_entity_died, fish_drop_entity_died)
