local Event = require 'utils.event'
local Token = require 'utils.global_token'
local Task = require 'utils.Task'
local PlayerStats = require 'player_stats'
local Game = require 'utils.game'

local market_items = require 'resources.market_items'

for _, item in ipairs(market_items) do
    local price = item.price[1]
    price[1] = 'raw-wood'
    price[2] = price[2] * 4
end

market_items[1].offer.effect_description = 'Temporary speed bonus - Price 40  Wood'
market_items[2].offer.effect_description = 'Temporary mining bonus - Price 40  Wood'

table.insert(market_items, {price = {{'raw-wood', 4}}, offer = {type = 'give-item', item = 'raw-fish'}})

local function spawn_market(cmd)
    if not game.player or not game.player.admin then
        cant_run(cmd.name)
        return
    end
    local surface = game.player.surface

    local player = game.player

    local market_location = {x = player.position.x, y = player.position.y}
    market_location.y = market_location.y - 4

    local market = surface.create_entity {name = 'market', position = market_location}
    market.destructible = false

    for _, item in ipairs(market_items) do
        market.add_market_item(item)
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
        local stack = {name = 'raw-wood', count = data.count * 4}
        data.surface.spill_item_stack(data.position, stack, true)
    end
)

local function wood_drop_entity_died(event)
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
    game.print(string.format(boost_msg[global.player_speed_boost_records[player.index].boost_lvl], player.name))
    if global.player_speed_boost_records[player.index].boost_lvl >= 4 then
        reset_player_runningspeed(player)
        player.character.die(player.force, market)
    end
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
    game.print(string.format(boost_msg[global.player_mining_boost_records[player.index].boost_lvl], player.name))
    if global.player_mining_boost_records[player.index].boost_lvl >= 4 then
        reset_player_miningspeed(player)
        player.character.die(player.force, market)
    end
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
    local cost = market_item.price[1].amount * event.count

    PlayerStats.change_fish_spent(player_index, cost)

    if event.offer_index == 1 then -- Temporary speed bonus
        local player = Game.get_player_by_index(player_index)
        boost_player_runningspeed(player, market)
    end

    if event.offer_index == 2 then -- Temporary mining bonus
        local player = Game.get_player_by_index(player_index)
        boost_player_miningspeed(player, market)
    end
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
end

local function player_mined_entity(event)
    local buffer = event.buffer

    if not buffer or not buffer.valid then
        return
    end

    local count = buffer.get_item_count('raw-wood')

    if count > 0 then
        PlayerStats.change_fish_earned(event.player_index, count)
    end
end

commands.add_command('market', 'Places a wood market near you.  (Admins only)', spawn_market)

Event.on_nth_tick(180, on_180_ticks)

Event.add(defines.events.on_entity_died, wood_drop_entity_died)
Event.add(defines.events.on_market_item_purchased, market_item_purchased)
Event.add(defines.events.on_player_mined_entity, player_mined_entity)
