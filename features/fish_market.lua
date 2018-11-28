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
local PlayerStats = require 'features.player_stats'
local Game = require 'utils.game'
local Utils = require 'utils.utils'

local Market_items = require 'resources.market_items'
local market_item = Market_items.market_item
local fish_market_bonus_message = require 'resources.fish_messages'
local total_fish_market_bonus_messages = #fish_market_bonus_message

local function spawn_market(cmd)
    local player = game.player
    if not player or not player.admin then
        Utils.cant_run(cmd.name)
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
 --

--[[
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
]]--

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
    global.player_speed_boost_records[player.index].boost_lvl = 1 + global.player_speed_boost_records[player.index].boost_lvl
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
    global.player_mining_boost_records[player.index].boost_lvl = 1 + global.player_mining_boost_records[player.index].boost_lvl
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

    if event.offer_index == 3 then -- train saviour item
        local player = Game.get_player_by_index(player_index)
        local train_savior_item = Market_items[offer_index].item
        player.insert {name = train_savior_item, count = event.count}
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
                    local player = Game.get_player_by_index(k)
                    if player.connected and player.character then
                        reset_player_runningspeed(player)
                    end
                end
            end
        end

        if global.player_mining_boost_records then
            for k, v in pairs(global.player_mining_boost_records) do
                if game.tick - v.start_tick > 6000 then
                    local player = Game.get_player_by_index(k)
                    if player.connected and player.character then
                        reset_player_miningspeed(player)
                    end
                end
            end
        end
    end

    --[[
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
    ]]--
end

local function fish_player_crafted_item(event)
    local x = math.random(1, 50)
    if x == 1 then
        fish_earned(event, 1)
    end
end

local function init()
    if global.config.fish_market.enable then
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
