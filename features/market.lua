local Event = require 'utils.event'
local Token = require 'utils.token'
local Task = require 'utils.task'
local PlayerStats = require 'features.player_stats'
local Game = require 'utils.game'
local Command = require 'utils.command'
local Retailer = require 'features.retailer'
local market_items = require 'resources.market_items'
local fish_market_bonus_message = require 'resources.fish_messages'
local pairs = pairs
local random = math.random
local format = string.format
local get_random = table.get_random
local currency = global.config.market.currency

local running_speed_boost_messages = {
    '%s found the lost Dragon Scroll and got a lv.1 speed boost!',
    'Guided by Master Oogway, %s got a lv.2 speed boost!',
    'Kung Fu Master %s defended the village and was awarded a lv.3 speed boost!',
    'Travelled at the speed of light. %s saw a black hole. Oops.',
}

local mining_speed_boost_messages = {
    '%s is going on a tree harvest!',
    'In search of a sharper axe, %s got a lv.2 mining boost!',
    'Wood fiend, %s, has picked up a massive chain saw and is awarded a lv.3 mining boost!',
    'Better learn to control that saw, %s, chopped off their legs. Oops.',
}

local function spawn_market(_, player)
    local surface = player.surface
    local force = player.force

    local pos = player.position
    pos.y = pos.y - 4

    local market = surface.create_entity({name = 'market', position = pos})
    market.destructible = false
    player.print("Market added. To remove it, highlight it with your cursor and run the command /sc game.player.selected.destroy()")

    Retailer.add_market('fish_market', market)

    for _, prototype in pairs(market_items) do
        Retailer.set_item('fish_market', prototype)
    end

    force.add_chart_tag(surface, {icon = {type = 'item', name = currency}, position = pos, text = 'Market'})
end

local function fish_earned(event, amount)
    local player_index = event.player_index
    local player = Game.get_player_by_index(player_index)

    local stack = {name = currency, count = amount}
    local inserted = player.insert(stack)

    local diff = amount - inserted
    if diff > 0 then
        stack.count = diff
        player.surface.spill_item_stack(player.position, stack, true)
    end

    PlayerStats.change_coin_earned(player_index, amount)

    if PlayerStats.get_coin_earned(player_index) % 70 == 0 and player and player.valid then
        local message = get_random(fish_market_bonus_message, true)
        player.print(message)
    end
end

local function pre_player_mined_item(event)
    local type = event.entity.type
    if type == 'simple-entity' then -- Cheap check for rock, may have other side effects
        fish_earned(event, 10)
        return
    end

    if type == 'tree' and random(1, 4) == 1 then
        fish_earned(event, 4)
    end
end

local entity_drop_amount = {
    ['biter-spawner'] = {low = 5, high = 15},
    ['spitter-spawner'] = {low = 5, high = 15},
    ['small-worm-turret'] = {low = 2, high = 8},
    ['medium-worm-turret'] = {low = 5, high = 15},
    ['big-worm-turret'] = {low = 10, high = 20}
}

local spill_items = Token.register(function(data)
    data.surface.spill_item_stack(data.position, {name = currency, count = data.count}, true)
end)

local function fish_drop_entity_died(event)
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    local bounds = entity_drop_amount[entity.name]
    if not bounds then
        return
    end

    local count = random(bounds.low, bounds.high)

    if count > 0 then
        Task.set_timeout_in_ticks(1, spill_items, {count = count, surface = entity.surface, position = entity.position})
    end
end

local function reset_player_running_speed(player)
    player.character_running_speed_modifier = global.player_speed_boost_records[player.index].pre_boost_modifier
    global.player_speed_boost_records[player.index] = nil
end

local function boost_player_running_speed(player)
    if global.player_speed_boost_records == nil then
        global.player_speed_boost_records = {}
    end

    if global.player_speed_boost_records[player.index] == nil then
        global.player_speed_boost_records[player.index] = {
            start_tick = game.tick,
            pre_boost_modifier = player.character_running_speed_modifier,
            boost_lvl = 0,
        }
    end
    global.player_speed_boost_records[player.index].boost_lvl =
        1 + global.player_speed_boost_records[player.index].boost_lvl

    player.character_running_speed_modifier = 1 + player.character_running_speed_modifier

    if global.player_speed_boost_records[player.index].boost_lvl >= 4 then
        game.print(format(running_speed_boost_messages[global.player_speed_boost_records[player.index].boost_lvl], player.name))
        reset_player_running_speed(player)
        player.character.die(player.force, player.character)
        return
    end

    player.print(format(running_speed_boost_messages[global.player_speed_boost_records[player.index].boost_lvl], player.name))
end

local function reset_player_mining_speed(player)
    player.character_mining_speed_modifier = global.player_mining_boost_records[player.index].pre_mining_boost_modifier
    global.player_mining_boost_records[player.index] = nil
end

local function boost_player_mining_speed(player)
    if global.player_mining_boost_records == nil then
        global.player_mining_boost_records = {}
    end

    if global.player_mining_boost_records[player.index] == nil then
        global.player_mining_boost_records[player.index] = {
            start_tick = game.tick,
            pre_mining_boost_modifier = player.character_mining_speed_modifier,
            boost_lvl = 0,
        }
    end
    global.player_mining_boost_records[player.index].boost_lvl =
        1 + global.player_mining_boost_records[player.index].boost_lvl

    if global.player_mining_boost_records[player.index].boost_lvl >= 4 then
        game.print(format(mining_speed_boost_messages[global.player_mining_boost_records[player.index].boost_lvl], player.name))
        reset_player_mining_speed(player)
        player.character.die(player.force, player.character)
        return
    end

    player.print(format(mining_speed_boost_messages[global.player_mining_boost_records[player.index].boost_lvl], player.name))
end

local function market_item_purchased(event)
    local item_name = event.item.name
    if item_name == 'temporary-running-speed-bonus' then
        boost_player_running_speed(event.player)
        return
    end

    if item_name == 'temporary-mining-speed-bonus' then
        boost_player_mining_speed(event.player)
        return
    end
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
    if random(1, 50) == 1 then
        fish_earned(event, 1)
    end
end

local function player_created(event)
    local player = Game.get_player_by_index(event.player_index)

    if not player or not player.valid then
        return
    end

    local count = global.config.player_rewards.info_player_reward and 1 or 10
    player.insert {name = currency, count = count}
end

Command.add(
    'market',
    {
        description = 'Places a market near you.',
        admin_only = true,
    },
    spawn_market
)

Event.on_nth_tick(180, on_180_ticks)
Event.add(defines.events.on_pre_player_mined_item, pre_player_mined_item)
Event.add(defines.events.on_entity_died, fish_drop_entity_died)
Event.add(Retailer.events.on_market_purchase, market_item_purchased)
Event.add(defines.events.on_player_crafted_item, fish_player_crafted_item)
Event.add(defines.events.on_player_created, player_created)
