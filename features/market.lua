-- dependencies
local Event = require 'utils.event'
local Token = require 'utils.token'
local Task = require 'utils.task'
local PlayerStats = require 'features.player_stats'
local Game = require 'utils.game'
local Command = require 'utils.command'
local Global = require 'utils.global'
local Retailer = require 'features.retailer'
local Ranks = require 'resources.ranks'
local RS = require 'map_gen.shared.redmew_surface'
local market_items = require 'resources.market_items'
local fish_market_bonus_message = require 'resources.fish_messages'

-- localized functions
local pairs = pairs
local round = math.round
local random = math.random
local format = string.format
local market_config = global.config.market
local currency = market_config.currency
local entity_drop_amount = market_config.entity_drop_amount

-- local vars

local nth_tick_token
local running_speed_boost_messages = {
    '%s found the lost Dragon Scroll and got a lv.1 speed boost!',
    'Guided by Master Oogway, %s got a lv.2 speed boost!',
    'Kung Fu Master %s defended the village and was awarded a lv.3 speed boost!',
    'Travelled at the speed of light. %s saw a black hole. Oops.'
}

local mining_speed_boost_messages = {
    '%s is going on a tree harvest!',
    'In search of a sharper axe, %s got a lv.2 mining boost!',
    'Wood fiend, %s, has picked up a massive chain saw and is awarded a lv.3 mining boost!',
    'Better learn to control that saw, %s, chopped off their legs. Oops.'
}

-- Global registered local vars
local primitives = {event_registered = nil}
local markets = {}
local speed_records = {}
local mining_records = {}

Global.register(
    {
        markets = markets,
        speed_records = speed_records,
        mining_records = mining_records,
        primitives = primitives
    },
    function(tbl)
        markets = tbl.markets
        speed_records = tbl.speed_records
        mining_records = tbl.mining_records
        primitives = tbl.primitives
    end
)

-- local functions

local function register_event()
    if not primitives.event_registered then
        Event.add_removable_nth_tick(907, nth_tick_token)
        primitives.event_registered = true
    end
end

local function unregister_event()
    if primitives.event_registered then
        Event.remove_removable_nth_tick(907, nth_tick_token)
        primitives.event_registered = nil
    end
end

local function spawn_market(args, player)
    if args and args.removeall == 'removeall' then
        local count = 0
        for _, market in pairs(markets) do
            if market.valid then
                count = count + 1
                market.destroy()
            end
        end
        player.print(count .. ' markets removed')
        return
    end
    local surface = RS.get_surface()
    local force = game.forces.player
    local maket_spawn_pos = market_config.standard_market_location

    if player then -- If we have a player, this is coming from a player running the command
        surface = player.surface
        force = player.force
        maket_spawn_pos = player.position
        maket_spawn_pos.y = round(maket_spawn_pos.y - 4)
        maket_spawn_pos.x = round(maket_spawn_pos.x)
        player.print('Market added. To remove it, highlight it with your cursor and use the /destroy command, or use /market removeall to remove all markets placed.')
    end

    local market = surface.create_entity({name = 'market', position = maket_spawn_pos})
    markets[#markets + 1] = market
    market.destructible = false

    Retailer.add_market('fish_market', market)

    if table.size(Retailer.get_items('fish_market')) == 0 then
        for _, prototype in pairs(market_items) do
            Retailer.set_item('fish_market', prototype)
        end
    end

    force.add_chart_tag(surface, {icon = {type = 'item', name = currency}, position = maket_spawn_pos, text = 'Market'})
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
        local message = fish_market_bonus_message[random(#fish_market_bonus_message)]
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

local spill_items =
    Token.register(
    function(data)
        data.surface.spill_item_stack(data.position, {name = currency, count = data.count}, true)
    end
)

-- Determines how many coins to drop when enemy entity dies based upon the entity_drop_amount table in config.lua
local function fish_drop_entity_died(event)
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    local bounds = entity_drop_amount[entity.name]
    if not bounds then
        return
    end

    local chance = bounds.chance

    if chance == 0 then
        return
    end

    if chance == 1 or random() <= chance then
        local count = random(bounds.low, bounds.high)
        if count > 0 then
            Task.set_timeout_in_ticks(
                1,
                spill_items,
                {
                    count = count,
                    surface = entity.surface,
                    position = entity.position
                }
            )
        end
    end
end

local function reset_player_running_speed(player)
    local index = player.index
    player.character_running_speed_modifier = speed_records[index].pre_boost_modifier
    speed_records[index] = nil
end

local function reset_player_mining_speed(player)
    local index = player.index
    player.character_mining_speed_modifier = mining_records[index].pre_mining_boost_modifier
    mining_records[index] = nil
end

local function boost_player_running_speed(player)
    local index = player.index
    local p_name = player.name
    if not speed_records[index] then
        speed_records[index] = {
            start_tick = game.tick,
            pre_boost_modifier = player.character_running_speed_modifier,
            boost_lvl = 0
        }
    end
    speed_records[index].boost_lvl = 1 + speed_records[index].boost_lvl

    player.character_running_speed_modifier = 1 + player.character_running_speed_modifier

    if speed_records[index].boost_lvl >= 4 then
        game.print(format(running_speed_boost_messages[speed_records[index].boost_lvl], p_name))
        reset_player_running_speed(player)
        player.character.die(player.force, player.character)
        return
    end

    player.print(format(running_speed_boost_messages[speed_records[index].boost_lvl], p_name))
    register_event()
end

local function boost_player_mining_speed(player)
    local index = player.index
    local p_name = player.name
    if not mining_records[index] then
        mining_records[index] = {
            start_tick = game.tick,
            pre_mining_boost_modifier = player.character_mining_speed_modifier,
            boost_lvl = 0
        }
    end
    mining_records[index].boost_lvl = 1 + mining_records[index].boost_lvl

    player.character_mining_speed_modifier = 1 + player.character_mining_speed_modifier

    if mining_records[index].boost_lvl >= 4 then
        game.print(format(mining_speed_boost_messages[mining_records[index].boost_lvl], p_name))
        reset_player_mining_speed(player)
        player.character.die(player.force, player.character)
        return
    end

    player.print(format(mining_speed_boost_messages[mining_records[index].boost_lvl], p_name))
    register_event()
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

nth_tick_token =
    Token.register(
    function()
        local tick = game.tick
        for k, v in pairs(speed_records) do
            if tick - v.start_tick > 3000 then
                local player = Game.get_player_by_index(k)
                if player and player.valid and player.connected and player.character then
                    reset_player_running_speed(player)
                end
            end
        end

        for k, v in pairs(mining_records) do
            if tick - v.start_tick > 6000 then
                local player = Game.get_player_by_index(k)
                if player and player.valid and player.connected and player.character then
                    reset_player_mining_speed(player)
                end
            end
        end

        if not next(speed_records) and not next(mining_records) then
            unregister_event()
        end
    end
)

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
        description = {'command_description.market'},
        arguments = {'removeall'},
        default_values = {removeall = false},
        required_rank = Ranks.admin
    },
    spawn_market
)

Event.add(defines.events.on_pre_player_mined_item, pre_player_mined_item)
Event.add(defines.events.on_entity_died, fish_drop_entity_died)
Event.add(Retailer.events.on_market_purchase, market_item_purchased)
Event.add(defines.events.on_player_crafted_item, fish_player_crafted_item)
Event.add(defines.events.on_player_created, player_created)
if global.config.market.create_standard_market then
    Event.on_init(spawn_market)
end
