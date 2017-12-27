--[[
Hello there script explorer!

With this you can add a "Fish Market" to your World
You can earn fish by killing alot of biters or by mining wood, ores, rocks.
To spawn the market, do "/market" in your chat ingame as the games host.
It will spawn a few tiles north of the current position where your character is.

---MewMew---


!! now with speed boost item addon from air20 !!

to be added(maybe)
fix pet health at refresh
make pet faster
make pet follow you moar
--]]

function spawn_market(cmd)
  if not game.player or not game.player.admin then
    cant_run(cmd.name)
    return
  end
  local surface = game.player.surface
  -- clear trees and landfill in start area
  local start_area = {left_top = {-20, -20}, right_bottom = {20, 20}}

  local player = game.player

  local market_location = {x = player.position.x, y = player.position.y}
  market_location.y = market_location.y - 4

  local market = surface.create_entity{name="market", position=market_location, force=force}
  market.destructible = false

  market.add_market_item{price={{"raw-fish", 10}}, offer={type="give-item", item="discharge-defense-remote"}}
  market.add_market_item{price={{"raw-fish", 30}}, offer={type="give-item", item="small-plane"}}
  market.add_market_item{price={{"raw-fish", 10}}, offer={type="give-item", item="wood"}}
  market.add_market_item{price={{"raw-fish", 1}}, offer={type="give-item", item="rail", count=2}}
  market.add_market_item{price={{"raw-fish", 2}}, offer={type="give-item", item="rail-signal"}}
  market.add_market_item{price={{"raw-fish", 2}}, offer={type="give-item", item="rail-chain-signal"}}
  market.add_market_item{price={{"raw-fish", 15}}, offer={type="give-item", item="train-stop"}}
  market.add_market_item{price={{"raw-fish", 75}}, offer={type="give-item", item="locomotive"}}
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
  market.add_market_item{price={{"raw-fish", 15}}, offer={type="give-item", item="steel-axe"}}
  market.add_market_item{price={{"raw-fish", 125}}, offer={type="give-item", item="rocket-launcher"}}
  market.add_market_item{price={{"raw-fish", 15}}, offer={type="give-item", item="rocket"}}
  market.add_market_item{price={{"raw-fish", 20}}, offer={type="give-item", item="explosive-rocket"}}
  market.add_market_item{price={{"raw-fish", 2500}}, offer={type="give-item", item="atomic-bomb"}}
  market.add_market_item{price={{"raw-fish", 25}}, offer={type="give-item", item="railgun"}}
  market.add_market_item{price={{"raw-fish", 10}}, offer={type="give-item", item="railgun-dart", count=10}}
  market.add_market_item{price={{"raw-fish", 100}}, offer={type="give-item", item="loader"}}
  market.add_market_item{price={{"raw-fish", 175}}, offer={type="give-item", item="fast-loader"}}
  market.add_market_item{price={{"raw-fish", 250}}, offer={type="give-item", item="express-loader"}}
  market.add_market_item{price={{"raw-fish", 500}}, offer={type="give-item", item="belt-immunity-equipment"}}
  market.add_market_item{price={{"raw-fish", 100}}, offer={type="give-item", item="night-vision-equipment"}}
  market.add_market_item{price={{"raw-fish", 200}}, offer={type="give-item", item="modular-armor"}}
  market.add_market_item{price={{"raw-fish", 500}}, offer={type="give-item", item="power-armor"}}
  market.add_market_item{price={{"raw-fish", 150}}, offer={type="give-item", item="personal-roboport-equipment"}}
  market.add_market_item{price={{"raw-fish", 50}}, offer={type="give-item", item="construction-robot", count=10}}
  market.add_market_item{price={{"raw-fish", 50}}, offer={type="give-item", item="solar-panel-equipment", count=1}}
  market.add_market_item{price={{"raw-fish", 50}}, offer={type="give-item", item="battery-equipment", count=1}}
  market.add_market_item{price={{"raw-fish", 750}}, offer={type="give-item", item="battery-mk2-equipment", count=1}}
  market.add_market_item{price={{"raw-fish", 1000}}, offer={type="give-item", item="fusion-reactor-equipment", count=1}}
  market.add_market_item{price={{"raw-fish", 100}}, offer={type="give-item", item="exoskeleton-equipment"}}

end

local fish_market_message = {}

local fish_market_bonus_message = {"Why don’t fish like basketball? Cause they’re afraid of the net", "What do you get when you cross a banker with a fish? A Loan shark!", "How do you make an Octupus laugh? With ten-tickles", "What do you call a fish that needs help with his or her vocals? Autotuna", "What is the difference between a piano and a fish? You can tune a piano but you cannot tuna fish.", "What did the blind man say when he passed the fish market? Good morning ladies.", "Did you hear about the goldfish who went bankrupt? Now he’s a bronze fish.", "What happens when you put nutella on salmon? You get salmonella", "What do you call a fish with no eyes?…Fsh", "What kind of money do fishermen make?…Net profits", "What do you get if you cross a salmon, a bird’s leg and a hand?…Birdsthigh fish fingers", "Why is a fish easy to weigh?…Because it has its own scales", "Why are gold fish orange?…The water makes them rusty", "What was the Tsar of Russia’s favorite fish?…Tsardines", "Why did the dog jump into the sea?…He wanted to chase the catfish", "Which fish dresses the best?…The Swordfish – It always looks sharp", "What do you get if you cross an abbot with a trout?…Monkfish", "What do you call a big fish who makes you an offer you can’t refuse?…The Codfather", "Why is a swordfish’s nose 11 inches long?…If it were 12 inches long it would be a foot", "What do you get if you cross a trout with an apartment?…A flat fish", "Why are fish no good at tennis?…They don’t like to get too close to the net", "How do the fish get to school?…By octobus", "What fish make the best sandwich?…A peanut butter and jellyfish", "Man: Can I have a fly rod and reel for my son?…Fishing Shop Owner: Sorry sir we don’t do trades", "Where do fish keep their money?…In the river bank", "Why do fish like arcade games?…Because they are finball wizards", "What is a mermaid?…A deep-she fish", "What do you get if you cross a whale with rotten fish?…Moby Sick", "Why didn’t the lobster share his toys?…He was too shellfish", "What do fish use to make telephone calls?…a Shell phone", "Why don’t fish make very good tennis balls?…They keep getting caught in the net", "Electric eels and electric rays have enough electricity to kill a horse.", "Most fish have taste buds all over their body.", "Most brands of lipstick contain fish scales.", "A fish does not add new scales as it grows, but the scales it has increase in size. In this way, growth rings are formed and the rings reveal the age of a fish.", "An inflated porcupine fish can reach a diameter of up to 35 inches. It puffs up by swallowing water and then storing it in its stomach.", "Most fish cannot swim backwards. Those that can are mainly members of one of the eel families.", "The fastest fish is the sailfish. It can swim as fast as a car travels on the highway.","Some desert pupfish can live in hot springs that reach temperatures greater than 113° F.","Anableps, four-eyed fish, can see above and below water at the same time.","Catfish have over 27,000 taste buds. Humans have around 7,000.","One hagfish can make enough slime in one minute to fill a bucket.","A female sunfish can lay 300 million eggs each year.", "Fish feel pain and suffer stress just like mammals and birds.", "The Dwarf Seahorse is so slow you can’t see it move", "Some fish are as small as a grain of rice", "There's a species of fish called 'Slippery Dick'", "Herrings communicate through farts.", "One Puffer Fish contains enough poison to kill 30 medium-biters.", "When Anglerfish mate, they melt into each other and share their bodies forever.", "A koi fish named 'Hanako' lived for 225 years.", "What did the fish say when he posted bail? I'm off the hook!","There was a sale at the fish market today. I went to see what was the catch.","There are over 25,000 identified species of fish on the earth."
}

local total_fish_market_messages = #fish_market_message
local total_fish_market_bonus_messages = #fish_market_bonus_message

if not global.fish_market_fish_caught then global.fish_market_fish_caught = {} end
if not global.fish_market_fish_spent then global.fish_market_fish_spent = {} end

local function fish_earned_index(player_index, amount)
   local player = game.players[player_index]
	player.insert { name = "raw-fish", count = amount }

	if global.fish_market_fish_caught[player_index] then
		global.fish_market_fish_caught[player_index] = global.fish_market_fish_caught[player_index] + amount
	else
		global.fish_market_fish_caught[player_index] = amount
	end

	if global.fish_market_fish_caught[player_index] <= total_fish_market_messages then
		local x = global.fish_market_fish_caught[player_index]
		player.print(fish_market_message[x])
	end

	local x = global.fish_market_fish_caught[player_index] % 70
	if x == 0 then
		local z = math.random(1,total_fish_market_bonus_messages)
		player.print(fish_market_bonus_message[z])
	end
end

local function fish_earned(event, amount)
   fish_earned_index( event.player_index, amount )
end

local function pre_player_mined_item(event)

   if event.entity.type == "simple-entity" then -- Cheap check for rock, may have other side effects
         fish_earned(event, 10)
   end

   if event.entity.type == "tree" then
		local x = math.random(1,4)
		if x == 1 then
			fish_earned(event, 4)
		end
	end
end

local function fish_drop_entity_died(event)
   local give_fish_cause = false
   local give_fish_unit = false
   local fish_amount = 0
   local fish_chance = 0 -- Out of 100

   if event.entity.force.name == "enemy" then
      if event.cause ~= nil then
         if event.cause.name == "gun-turret" or event.cause.name == "flamethrower-turret" then
            -- WHo's around to get free fish!?
            give_fish_cause = true
         elseif event.cause.type == "player" then
            give_fish_cause = true
         end
      else
         -- Unknown cause? Free fish! Worms have no cause
         give_fish_cause = true
      end
      if event.entity.type == "unit" then
         fish_amount = 3
         fish_chance = 1
         give_fish_unit = true
      end
      if event.entity.type == "unit-spawner" then
         fish_amount = 10
         fish_chance = 100
         give_fish_unit = true
      end
      if event.entity.type == "turret" then
         if ( event.entity.name == "small-worm-turret" ) then
            fish_amount = 5
         elseif ( event.entity.name == "medium-worm-turret" ) then
            fish_amount = 10
         elseif ( event.entity.name == "big-worm-turret" ) then
            fish_amount = 15
         end

         fish_chance = 100
         give_fish_unit = true
      end

      if give_fish_unit and give_fish_cause then
         local x = math.random(1,100)
         if x  <= fish_chance then
            -- Find nearby players +/- 16 blocks of event
            local block_size = 64
            area = {{event.entity.position.x - block_size, event.entity.position.y - block_size}, {event.entity.position.x + block_size, event.entity.position.y + block_size}}
            player_entities = game.surfaces[1].find_entities_filtered( { area = area, type = "player", force = "player" } )

            for _,entity in ipairs(player_entities) do
               if entity.player.afk_time < 120  then
                  fish_earned_index(entity.player.index, fish_amount)
               end
            end

         end
      end

      if global.score_biter_total_kills % 150 == 0 then
         local surface = event.entity.surface
         local x = math.random(1,2)
         surface.spill_item_stack(event.entity.position, { name = "raw-fish", count = x }, 1)
      end
   end
end


function pet(player, entity_name)
	if not player then
		player = game.connected_players[1]
	else
		player = game.players[player]
	end
	if not entity_name then
		entity_name = "small-biter"
	end
	if not global.player_pets then global.player_pets = {} end

	local surface = player.surface

	local pos = player.position
	pos.y = pos.y + 1

	local x = 1
	x = x + #global.player_pets

	global.player_pets[x] = {}
	global.player_pets[x].entity = surface.create_entity {name=entity_name, position=pos, force="player"}
	global.player_pets[x].owner = player.index
	global.player_pets[x].id = x

end

local function reset_player_runningspeed(player)
  player.character_running_speed_modifier = global.player_speed_boost_records[player.index].pre_boost_modifier
  global.player_speed_boost_records[player.index] = nil
end

local function boost_player_runningspeed(player)
  if global.player_speed_boost_records == nil then global.player_speed_boost_records = {} end

  if global.player_speed_boost_records[player.index] == nil then
    global.player_speed_boost_records[player.index] = {
      start_tick = game.tick,
      pre_boost_modifier = player.character_running_speed_modifier,
      boost_lvl = 0
    }
  end
  local boost_msg = {
    [1] = "%s found the lost Dragon Scroll and got a lv.1 speed boost!",
    [2] = "Guided by Master Oogway, %s got a lv.2 speed boost!",
    [3] = "Kungfu Master %s defended the village and was awarded a lv.3 speed boost!",
    [4] = "Travelled at the speed of light. %s saw a blackhole. Oops."
  }
  global.player_speed_boost_records[player.index].boost_lvl = 1 + global.player_speed_boost_records[player.index].boost_lvl
  player.character_running_speed_modifier = 1 + player.character_running_speed_modifier
  game.print(string.format(boost_msg[global.player_speed_boost_records[player.index].boost_lvl], player.name))
  if global.player_speed_boost_records[player.index].boost_lvl >= 4 then
    reset_player_runningspeed(player)
    player.character.die()
  end
end

local function reset_player_miningspeed(player)
  player.character_mining_speed_modifier = global.player_mining_boost_records[player.index].pre_mining_boost_modifier
  global.player_mining_boost_records[player.index] = nil
end

local function boost_player_miningspeed(player)
  if global.player_mining_boost_records == nil then global.player_mining_boost_records = {} end

  if global.player_mining_boost_records[player.index] == nil then
    global.player_mining_boost_records[player.index] = {
      start_tick = game.tick,
      pre_mining_boost_modifier = player.character_mining_speed_modifier,
      boost_lvl = 0
    }
  end
  local boost_msg = {
    [1] = "%s is going on a tree harvest!",
    [2] = "In search of a sharper axe, %s got a lv.2 mining boost!",
    [3] = "Wood fiend, %s, has picked up a massive chain saw and is awarded a lv.3 mining boost!",
    [4] = "Better learn to control that saw, %s, chopped off their legs. Oops."
  }
  global.player_mining_boost_records[player.index].boost_lvl = 1 + global.player_mining_boost_records[player.index].boost_lvl
  player.character_mining_speed_modifier = 1 + player.character_mining_speed_modifier
  game.print(string.format(boost_msg[global.player_mining_boost_records[player.index].boost_lvl], player.name))
  if global.player_mining_boost_records[player.index].boost_lvl >= 4 then
    reset_player_miningspeed(player)
    player.character.die()
  end
end

local function market_item_purchased(event)

  local player = game.players[event.player_index]

  -- cost
  market_items = event.market.get_market_items()
  market_item = market_items[event.offer_index]
  fish_cost = market_item.price[1].amount * event.count
  global.fish_market_fish_spent[event.player_index] = global.fish_market_fish_spent[event.player_index] + fish_cost

  --to reenable buffs and pets remove this block:
    if event.offer_index < 4 then 

      local fish_amount = 10
      if event.offer_index == 2 then fish_amount = 30 end
      player.insert{name="raw-fish", count = fish_amount}
      player.remove_item{name="small-plane", count = 100}
      player.remove_item{name="discharge-defense-remote", count = 100}--nobody useds that anyways
      player.remove_item{name="wood", count = event.count}
      player.print("This item is currently disabled due to desync concerns. Please don't hurt us :(")
    end

    return     
  --upto here

  if event.offer_index == 1 then -- discharge-defense-remote
    player.remove_item({name="discharge-defense-remote", count=event.count})
    boost_player_runningspeed(player) --disabled due to on_tick being disabled
  end

  if event.offer_index == 3 then -- exoskeleton-equipment
    player.remove_item({name="wood", count=event.count})
    boost_player_miningspeed(player)
  end

  if event.offer_index == 2 then
    player.remove_item({name="small-plane", count=event.count})
    local chance = 4
    local x = math.random(1,3)
    if x < 3 then
      local x = math.random(1,chance)
      if x < chance then
        rolled_pet = "small-biter"
      else
        local x = math.random(1,chance)
        if x < chance then
          rolled_pet = "medium-biter"
        else
          local x = math.random(1,chance)
          if x < chance then
            rolled_pet = "big-biter"
          else
            rolled_pet = "behemoth-biter"
          end
        end
      end
    else
      local x = math.random(1,chance)
      if x < chance then
        rolled_pet = "small-spitter"
      else
        local x = math.random(1,chance)
        if x < chance then
          rolled_pet = "medium-spitter"
        else
          local x = math.random(1,chance)
          if x < chance then
            rolled_pet = "big-spitter"
          else
            rolled_pet = "behemoth-spitter"
          end
        end
      end
    end
    local str = string.format("%s bought his very own pet %s at the fish market!!", player.name, rolled_pet)
    game.print(str)
    pet(event.player_index, rolled_pet)
  end
end

if not global.pet_command_rotation then global.pet_command_rotation = 1 end

function fish_market_on_180_ticks()

  if game.tick % 900 == 0 then
     if global.player_speed_boost_records then
   		for k,v in pairs(global.player_speed_boost_records) do
   		  if game.tick - v.start_tick > 3000 then
   			reset_player_runningspeed(game.players[k])
   		  end
   		end
   	end
      if global.player_mining_boost_records then
         for k,v in pairs(global.player_mining_boost_records) do
            if game.tick - v.start_tick > 6000 then
               reset_player_miningspeed(game.players[k])
            end
         end
      end
   end

  if global.player_pets then
  	for _, pets in pairs(global.player_pets) do
  		local player = game.players[pets.owner]
  		if pcall(function () local x = pets.entity.name end) then
  			if global.pet_command_rotation % 15 == 0 then
  				local surface = player.surface
  				local pet_pos = pets.entity.position
  				local pet_name = pets.entity.name
  				local pet_direction = pets.entity.direction
  				pets.entity.destroy()
  				pets.entity = surface.create_entity {name=pet_name, position=pet_pos, direction=pet_direction, force="player"}
  			end
  			if global.pet_command_rotation % 2 == 1 then
  				pets.entity.set_command({type=defines.command.go_to_location, destination=player.position,distraction=defines.distraction.none})
  			else
  				local fake_pos = pets.entity.position
  				pets.entity.set_command({type=defines.command.go_to_location, destination=fake_pos,distraction=defines.distraction.none})
  			end
  		else
  			global.player_pets[pets.id] = nil
  			local str = player.name .. "´s pet died ;_;"
  			game.print(str)
  		end
  	end
  	global.pet_command_rotation = global.pet_command_rotation + 1
  end
end

function fish_player_crafted_item(event)
   local x = math.random(1,50)
   if x == 1 then
      fish_earned(event, 1)
   end
end

Event.register(defines.events.on_pre_player_mined_item, pre_player_mined_item)
Event.register(defines.events.on_entity_died, fish_drop_entity_died)
Event.register(defines.events.on_market_item_purchased, market_item_purchased)
Event.register(defines.events.on_player_crafted_item, fish_player_crafted_item)
