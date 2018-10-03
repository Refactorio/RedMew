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
local Event = require 'utils.event'
local Token = require 'utils.global_token'
local Task = require 'utils.Task'
local PlayerStats = require 'player_stats'
local Game = require 'utils.game'

local Market_items = require 'resources.market_items'
local market_item = Market_items.market_item

local function spawn_market(cmd)
    local player = game.player
    if not player or not player.admin then
        cant_run(cmd.name)
        return
    end

    local surface = player.surface
    local force = player.force

    local pos = player.position
    pos.y = pos.y - 4

    local market = surface.create_entity {name = 'market', position = pos}
    market.destructible = false

    for _, item in ipairs(Market_items) do
        market.add_market_item(item)
    end

    force.add_chart_tag(
        surface,
        {
            icon = {type = 'item', name = market_item},
            position = pos,
            text = ' Market'
        }
    )
end

local fish_market_bonus_message = {
    'Why don’t fish like basketball? Cause they’re afraid of the net',
    'What do you get when you cross a banker with a fish? A Loan shark!',
    'How do you make an Octupus laugh? With ten-tickles',
    'What do you call a fish that needs help with his or her vocals? Autotuna',
    'What is the difference between a piano and a fish? You can tune a piano but you cannot tuna fish.',
    'What did the blind man say when he passed the fish market? Good morning ladies.',
    'Did you hear about the goldfish who went bankrupt? Now he’s a bronze fish.',
    'What happens when you put nutella on salmon? You get salmonella',
    'What do you call a fish with no eyes?…Fsh',
    'What kind of money do fishermen make?…Net profits',
    'What do you get if you cross a salmon, a bird’s leg and a hand?…Birdsthigh fish fingers',
    'Why is a fish easy to weigh?…Because it has its own scales',
    'Why are gold fish orange?…The water makes them rusty',
    'What was the Tsar of Russia’s favorite fish?…Tsardines',
    'Why did the dog jump into the sea?…He wanted to chase the catfish',
    'Which fish dresses the best?…The Swordfish – It always looks sharp',
    'What do you get if you cross an abbot with a trout?…Monkfish',
    'What do you call a big fish who makes you an offer you can’t refuse?…The Codfather',
    'Why is a swordfish’s nose 11 inches long?…If it were 12 inches long it would be a foot',
    'What do you get if you cross a trout with an apartment?…A flat fish',
    'Why are fish no good at tennis?…They don’t like to get too close to the net',
    'How do the fish get to school?…By octobus',
    'What fish make the best sandwich?…A peanut butter and jellyfish',
    'Man: Can I have a fly rod and reel for my son?…Fishing Shop Owner: Sorry sir we don’t do trades',
    'Where do fish keep their money?…In the river bank',
    'Why do fish like arcade games?…Because they are finball wizards',
    'What is a mermaid?…A deep-she fish',
    'What do you get if you cross a whale with rotten fish?…Moby Sick',
    'Why didn’t the lobster share his toys?…He was too shellfish',
    'What do fish use to make telephone calls?…a Shell phone',
    'Why don’t fish make very good tennis balls?…They keep getting caught in the net',
    'Electric eels and electric rays have enough electricity to kill a horse.',
    'Most fish have taste buds all over their body.',
    'Most brands of lipstick contain fish scales.',
    'A fish does not add new scales as it grows, but the scales it has increase in size. In this way, growth rings are formed and the rings reveal the age of a fish.',
    'An inflated porcupine fish can reach a diameter of up to 35 inches. It puffs up by swallowing water and then storing it in its stomach.',
    'Most fish cannot swim backwards. Those that can are mainly members of one of the eel families.',
    'The fastest fish is the sailfish. It can swim as fast as a car travels on the highway.',
    'Some desert pupfish can live in hot springs that reach temperatures greater than 113° F.',
    'Anableps, four-eyed fish, can see above and below water at the same time.',
    'Catfish have over 27,000 taste buds. Humans have around 7,000.',
    'One hagfish can make enough slime in one minute to fill a bucket.',
    'A female sunfish can lay 300 million eggs each year.',
    'Fish feel pain and suffer stress just like mammals and birds.',
    'The Dwarf Seahorse is so slow you can’t see it move',
    'Some fish are as small as a grain of rice',
    "There's a species of fish called 'Slippery Dick'",
    'Herrings communicate through farts.',
    'One Puffer Fish contains enough poison to kill 30 medium-biters.',
    'When Anglerfish mate, they melt into each other and share their bodies forever.',
    "A koi fish named 'Hanako' lived for 225 years.",
    "What did the fish say when he posted bail? I'm off the hook!",
    'There was a sale at the fish market today. I went to see what was the catch.',
    'There are over 25,000 identified species of fish on the earth.'
}

local total_fish_market_bonus_messages = #fish_market_bonus_message

local function fish_earned(event, amount)
    local player_index = event.player_index
    local player = Game.get_player_by_index(player_index)

    local stack = {name = market_item, count = amount}
    local inserted = player.insert(stack)

    local diff = amount - inserted
    if diff > 0 then
        stack.count = diff
        player.surface.spill_item_stack(player.position, stack, true)
    end

    local fish = PlayerStats.get_coin_earned(player_index)
    fish = fish + amount
    PlayerStats.set_coin_earned(player_index, fish)

    if fish % 70 == 0 then
        if player and player.valid then
            local message = fish_market_bonus_message[math.random(total_fish_market_bonus_messages)]
            player.print(message)
        end
    end
end

local function pre_player_mined_item(event)
    if event.entity.type == 'simple-entity' then -- Cheap check for rock, may have other side effects
        fish_earned(event, 10)
        return
    end

    if event.entity.type == 'tree' then
        local x = math.random(1, 4)
        if x == 1 then
            fish_earned(event, 4)
        end
    end
end

local entity_drop_amount = {
    --[[['small-biter'] = {low = -62, high = 1},
    ['small-spitter'] = {low = -62, high = 1},
    ['medium-biter'] = {low = -14, high = 1},
    ['medium-spitter'] = {low = -14, high = 1},
    ['big-biter'] = {low = -2, high = 1},
    ['big-spitter'] = {low = -2, high = 1},
    ['behemoth-biter'] = {low = 1, high = 1},
    ['behemoth-spitter'] = {low = 1, high = 1}, ]]
    ['biter-spawner'] = {low = 5, high = 15},
    ['spitter-spawner'] = {low = 5, high = 15},
    ['small-worm-turret'] = {low = 2, high = 8},
    ['medium-worm-turret'] = {low = 5, high = 15},
    ['big-worm-turret'] = {low = 10, high = 20}
}

local spill_items =
    Token.register(
    function(data)
        local stack = {name = market_item, count = data.count}
        data.surface.spill_item_stack(data.position, stack, true)
    end
)

local function fish_drop_entity_died(event)
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    local bounds = entity_drop_amount[entity.name]
    if not bounds then
        return
    end

    local count = math.random(bounds.low, bounds.high)

    if count > 0 then
        Task.set_timeout_in_ticks(1, spill_items, {count = count, surface = entity.surface, position = entity.position})
    end
end

local function pet(player, entity_name)
    if not player then
        player = game.connected_players[1]
    else
        player = game.players[player]
    end
    if not entity_name then
        entity_name = 'small-biter'
    end
    if not global.player_pets then
        global.player_pets = {}
    end

    local surface = player.surface

    local pos = player.position
    pos.y = pos.y + 1

    local x = 1
    x = x + #global.player_pets

    global.player_pets[x] = {}
    global.player_pets[x].entity = surface.create_entity {name = entity_name, position = pos, force = 'player'}
    global.player_pets[x].owner = player.index
    global.player_pets[x].id = x
end

local function reset_player_runningspeed(player)
    player.character_running_speed_modifier = global.player_speed_boost_records[player.index].pre_boost_modifier
    global.player_speed_boost_records[player.index] = nil
end

local function boost_player_runningspeed(player, market)
    if global.player_speed_boost_records == nil then
        global.player_speed_boost_records = {}
    end

    if global.player_speed_boost_records[player.index] == nil then
        global.player_speed_boost_records[player.index] = {
            start_tick = game.tick,
            pre_boost_modifier = player.character_running_speed_modifier,
            boost_lvl = 0
        }
    end
    local boost_msg = {
        [1] = '%s found the lost Dragon Scroll and got a lv.1 speed boost!',
        [2] = 'Guided by Master Oogway, %s got a lv.2 speed boost!',
        [3] = 'Kungfu Master %s defended the village and was awarded a lv.3 speed boost!',
        [4] = 'Travelled at the speed of light. %s saw a blackhole. Oops.'
    }
    global.player_speed_boost_records[player.index].boost_lvl =
        1 + global.player_speed_boost_records[player.index].boost_lvl
    player.character_running_speed_modifier = 1 + player.character_running_speed_modifier

    if global.player_speed_boost_records[player.index].boost_lvl >= 4 then
        game.print(string.format(boost_msg[global.player_speed_boost_records[player.index].boost_lvl], player.name))
        reset_player_runningspeed(player)
        player.character.die(player.force, market)
        return
    end

    player.print(string.format(boost_msg[global.player_speed_boost_records[player.index].boost_lvl], player.name))
end

local function reset_player_miningspeed(player)
    player.character_mining_speed_modifier = global.player_mining_boost_records[player.index].pre_mining_boost_modifier
    global.player_mining_boost_records[player.index] = nil
end

local function boost_player_miningspeed(player, market)
    if global.player_mining_boost_records == nil then
        global.player_mining_boost_records = {}
    end

    if global.player_mining_boost_records[player.index] == nil then
        global.player_mining_boost_records[player.index] = {
            start_tick = game.tick,
            pre_mining_boost_modifier = player.character_mining_speed_modifier,
            boost_lvl = 0
        }
    end
    local boost_msg = {
        [1] = '%s is going on a tree harvest!',
        [2] = 'In search of a sharper axe, %s got a lv.2 mining boost!',
        [3] = 'Wood fiend, %s, has picked up a massive chain saw and is awarded a lv.3 mining boost!',
        [4] = 'Better learn to control that saw, %s, chopped off their legs. Oops.'
    }
    global.player_mining_boost_records[player.index].boost_lvl =
        1 + global.player_mining_boost_records[player.index].boost_lvl
    player.character_mining_speed_modifier = 1 + player.character_mining_speed_modifier

    if global.player_mining_boost_records[player.index].boost_lvl >= 4 then
        game.print(string.format(boost_msg[global.player_mining_boost_records[player.index].boost_lvl], player.name))
        reset_player_miningspeed(player)
        player.character.die(player.force, market)
        return
    end

    player.print(string.format(boost_msg[global.player_mining_boost_records[player.index].boost_lvl], player.name))
end

local function market_item_purchased(event)
    local market = event.market
    if not market or not market.valid then
        return
    end

    local offer_index = event.offer_index
    local player_index = event.player_index

    -- cost
    local market_item = market.get_market_items()[offer_index]
    local fish_cost = market_item.price[1].amount * event.count

    PlayerStats.change_coin_spent(player_index, fish_cost)

    if event.offer_index == 1 then -- Temporary speed bonus
        local player = Game.get_player_by_index(player_index)
        boost_player_runningspeed(player, market)
    end

    if event.offer_index == 2 then -- Temporary mining bonus
        local player = Game.get_player_by_index(player_index)
        boost_player_miningspeed(player, market)
    end

    --[[
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
  --]]
end

if not global.pet_command_rotation then
    global.pet_command_rotation = 1
end

local function on_180_ticks()
    if game.tick % 900 == 0 then
        if global.player_speed_boost_records then
            for k, v in pairs(global.player_speed_boost_records) do
                if game.tick - v.start_tick > 3000 then
                    reset_player_runningspeed(Game.get_player_by_index(k))
                end
            end
        end
        if global.player_mining_boost_records then
            for k, v in pairs(global.player_mining_boost_records) do
                if game.tick - v.start_tick > 6000 then
                    reset_player_miningspeed(Game.get_player_by_index(k))
                end
            end
        end
    end

    if global.player_pets then
        for _, pets in pairs(global.player_pets) do
            local player = game.players[pets.owner]
            if
                pcall(
                    function()
                        local x = pets.entity.name
                    end
                )
             then
                if global.pet_command_rotation % 15 == 0 then
                    local surface = player.surface
                    local pet_pos = pets.entity.position
                    local pet_name = pets.entity.name
                    local pet_direction = pets.entity.direction
                    pets.entity.destroy()
                    pets.entity =
                        surface.create_entity {
                        name = pet_name,
                        position = pet_pos,
                        direction = pet_direction,
                        force = 'player'
                    }
                end
                if global.pet_command_rotation % 2 == 1 then
                    pets.entity.set_command(
                        {
                            type = defines.command.go_to_location,
                            destination = player.position,
                            distraction = defines.distraction.none
                        }
                    )
                else
                    local fake_pos = pets.entity.position
                    pets.entity.set_command(
                        {
                            type = defines.command.go_to_location,
                            destination = fake_pos,
                            distraction = defines.distraction.none
                        }
                    )
                end
            else
                global.player_pets[pets.id] = nil
                local str = player.name .. '´s pet died ;_;'
                game.print(str)
            end
        end
        global.pet_command_rotation = global.pet_command_rotation + 1
    end
end

local function fish_player_crafted_item(event)
    local x = math.random(1, 50)
    if x == 1 then
        fish_earned(event, 1)
    end
end

local function init()

  if global.scenario.config.fish_market.enable then
    commands.add_command('market', 'Places a fish market near you.  (Admins only)', spawn_market)

    Event.on_nth_tick(180, on_180_ticks)
    Event.add(defines.events.on_pre_player_mined_item, pre_player_mined_item)
    Event.add(defines.events.on_entity_died, fish_drop_entity_died)
    Event.add(defines.events.on_market_item_purchased, market_item_purchased)
    Event.add(defines.events.on_player_crafted_item, fish_player_crafted_item)
  end
end
Event.on_init(init)
Event.on_load(init)
