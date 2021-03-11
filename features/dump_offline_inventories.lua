-- This feature allows you to turn on anti-hoarding so that X minutes after a player leaves the game
-- the resources in their inventory are returned to the teams. A corpse will spawn on the player's last
-- position and remain until they log back in to claim it or someone else mines it.

local Event = require 'utils.event'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Global = require 'utils.global'
local CorpseUtil = require 'features.corpse_util'

local set_timeout_in_ticks = Task.set_timeout_in_ticks
local config = global.config.dump_offline_inventories
local offline_timout_mins = config.offline_timout_mins

local offline_player_queue = {}
Global.register(offline_player_queue, function(tbl)
    offline_player_queue = tbl
end)

local spawn_player_corpse =
    Token.register(
    function(data)
        local player = data.player
        if not player or not player.valid then
            return
        end

        local player_index = player.index
        local queue_data = offline_player_queue[player_index]
        if queue_data ~= data.tick then
            return
        end

        offline_player_queue[player_index] = nil

        if player.connected then
            return
        end

        local inv_main = player.get_inventory(defines.inventory.character_main)
        local inv_trash = player.get_inventory(defines.inventory.character_trash)

        local inv_main_contents = inv_main.get_contents()
        local inv_trash_contents = inv_trash.get_contents()

        local inv_corpse_size = (#inv_main - inv_main.count_empty_stacks()) + (#inv_trash - inv_trash.count_empty_stacks())

        if inv_corpse_size <= 0 then
            return
        end

        local position = player.position
        local corpse = player.surface.create_entity{name = "character-corpse", position = position, inventory_size = inv_corpse_size, player_index = player_index}
        corpse.active = false

        local inv_corpse = corpse.get_inventory(defines.inventory.character_corpse)

        for item_name, count in pairs(inv_main_contents) do
            inv_corpse.insert({name = item_name, count = count})
        end
        for item_name, count in pairs(inv_trash_contents) do
            inv_corpse.insert({name = item_name, count = count})
        end

        inv_main.clear()
        inv_trash.clear()

        local text = player.name .. "'s inventory (offline)"
        local tag = player.force.add_chart_tag(player.surface, {
            icon = {type = 'item', name = 'modular-armor'},
            position = position,
            text = text
        })

        local message = {
            'dump_offline_inventories.inventory_location',
            player.name,
            offline_timout_mins,
            string.format('%.1f', position.x),
            string.format('%.1f', position.y),
            player.surface.name
        }
        game.print(message)

        if tag then
            CorpseUtil.add_tag(tag, player_index, game.tick, false)
        end
    end
)

local function start_timer(event, timeout)
    local player_index = event.player_index
    local player = game.get_player(player_index)

    if player and player.valid and player.character then -- if player leaves before respawning they wont have a character and we don't need to add them to the list
        local tick = game.tick
        offline_player_queue[player_index] = tick  -- tick is used to check that the callback happens after X minutes as multiple callbacks may be active if the player logs off and on multiple times
        set_timeout_in_ticks(timeout, spawn_player_corpse, {player = player, tick = tick})
    end
end

Event.add(defines.events.on_pre_player_left_game, function(event)
    local timeout = offline_timout_mins * 60 * 60
    start_timer(event, timeout)
end)

Event.add(defines.events.on_player_banned, function(event)
    start_timer(event, 60)
end)