--[[
Hello there script explorer!

With this you can add a "Fish Market" to your World
You can earn fish by killing alot of biters or by mining wood, ores, rocks.
To spawn the market, do "/market" in your chat ingame as the games host.
It will spawn a few tiles north of the current position where your character is.

---MewMew---

--]]
local Event = require 'utils.event'
local Token = require 'utils.token'
local Task = require 'utils.Task'
local PlayerStats = require 'features.player_stats'
local Game = require 'utils.game'
local Utils = require 'utils.core'

local Market_items = require 'resources.market_items'
local market_item = Market_items.market_item
local fish_market_bonus_message = require 'resources.fish_messages'

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
            local message = table.get_random(fish_market_bonus_message, true)
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


local function reset_player_running_speed(player)
    player.character_running_speed_modifier = global.player_speed_boost_records[player.index].pre_boost_modifier
    global.player_speed_boost_records[player.index] = nil
end

local function boost_player_running_speed(player, market)
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
        reset_player_running_speed(player)
        player.character.die(player.force, market)
        return
    end

    player.print(string.format(boost_msg[global.player_speed_boost_records[player.index].boost_lvl], player.name))
end

local function reset_player_mining_speed(player)
    player.character_mining_speed_modifier = global.player_mining_boost_records[player.index].pre_mining_boost_modifier
    global.player_mining_boost_records[player.index] = nil
end

local function boost_player_mining_speed(player, market)
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
        reset_player_mining_speed(player)
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
        boost_player_running_speed(player, market)
    end

    if event.offer_index == 2 then -- Temporary mining bonus
        local player = Game.get_player_by_index(player_index)
        boost_player_mining_speed(player, market)
    end

    if event.offer_index == 3 then -- train saviour item
        local player = Game.get_player_by_index(player_index)
        local train_savior_item = Market_items[offer_index].item
        player.insert {name = train_savior_item, count = event.count}
    end
end

if not global.pet_command_rotation then
    global.pet_command_rotation = 1
end

local function on_180_ticks()
    local tick = game.tick
    if tick % 900 == 0 then
        if global.player_speed_boost_records then
            for k, v in pairs(global.player_speed_boost_records) do
                if tick - v.start_tick > 3000 then
                    local player = Game.get_player_by_index(k)
                    if player.connected and player.character then
                        reset_player_running_speed(player)
                    end
                end
            end
        end

        if global.player_mining_boost_records then
            for k, v in pairs(global.player_mining_boost_records) do
                if tick - v.start_tick > 6000 then
                    local player = Game.get_player_by_index(k)
                    if player.connected and player.character then
                        reset_player_mining_speed(player)
                    end
                end
            end
        end
    end
end

local function fish_player_crafted_item(event)
    local x = math.random(1, 50)
    if x == 1 then
        fish_earned(event, 1)
    end
end

local function player_created(event)
    local player = Game.get_player_by_index(event.player_index)

    if not player or not player.valid then
        return
    end

    player.insert {name = market_item, count = 10}
end

local function init()
    commands.add_command('market', 'Places a fish market near you.  (Admins only)', spawn_market)

    Event.on_nth_tick(180, on_180_ticks)
    Event.add(defines.events.on_pre_player_mined_item, pre_player_mined_item)
    Event.add(defines.events.on_entity_died, fish_drop_entity_died)
    Event.add(defines.events.on_market_item_purchased, market_item_purchased)
    Event.add(defines.events.on_player_crafted_item, fish_player_crafted_item)
    Event.add(defines.events.on_player_created, player_created)
end

Event.on_init(init)
Event.on_load(init)
