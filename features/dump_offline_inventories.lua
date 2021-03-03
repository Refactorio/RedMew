-- This feature allows you to turn on anti-hoarding so that X minutes after a player leaves the game
-- the resources in their inventory are returned to the teams. A corpse will spawn on the player's last
-- position and remain until they log back in to claim it or someone else mines it.

local Event = require 'utils.event'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Global = require 'utils.global'
local corpse_util = require 'features.corpse_util'

local set_timeout_in_ticks = Task.set_timeout_in_ticks
local config = global.config.dump_offline_inventories
local offline_timout_mins = config.offline_timout_mins

local offline_player_queue = {}
Global.register({offline_player_queue = offline_player_queue}, function(tbl)
    offline_player_queue = tbl.offline_player_queue
end)

local spawn_player_corpse =
    Token.register(
    function(data)
        local player = data.player
        if not player or not player.valid or player.connected or not offline_player_queue[player.index] or offline_player_queue[player.index].tick ~= data.tick then
            return
        end

        game.print("Debug: callback reached")
        local inv_main = player.get_inventory(defines.inventory.character_main)
        local inv_trash = player.get_inventory(defines.inventory.character_trash)

        local inv_main_contents = inv_main.get_contents()
        local inv_trash_contents = inv_trash.get_contents()

        local inv_corpse_size = (#inv_main - inv_main.count_empty_stacks()) + (#inv_trash - inv_trash.count_empty_stacks())

        local position = player.position
        local corpse = player.surface.create_entity{name="character-corpse", position=position, inventory_size = inv_corpse_size, player_index = player.index}
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

        offline_player_queue[data.player.index] = nil

        local text = player.name .. "'s inventory (offline)"
        local tag = player.force.add_chart_tag(player.surface, {
            icon = {type = 'item', name = 'modular-armor'},
            position = position,
            text = text
        })
        if tag then
            corpse_util.player_corpses[player.index * 0x100000000 + game.tick] = tag
        end
    end
)

Event.add(
    defines.events.on_player_joined_game,
    function(event)
        offline_player_queue[event.player_index] = nil -- ensures they're not in the offline_player_queue for wealth redistribution
        game.print("Debug: player removed from queue")
    end
)

Event.add(
    defines.events.on_pre_player_left_game,
    function(event)
        local player_index = event.player_index
        local player = game.get_player(player_index)
        if player and player.valid and player.character then -- if player leaves before respawning they wont have a character and we don't need to add them to the list
            offline_player_queue[player_index] = game.tick  -- tick is used to check that the callback happens after X minutes as multiple callbacks may be active if the player logs off and on multiple times
            game.print("Debug: player added to queue")
            set_timeout_in_ticks(offline_timout_mins*60*60, spawn_player_corpse, {player = player, tick = game.tick})
        end
    end
)

Event.add(
    defines.events.on_player_banned,
    function(event)
        local player_index = event.player_index
        local player = game.get_player(player_index)
        if player and player.valid and player.character then -- if player leaves before respawning they wont have a character and we don't need to add them to the list
            offline_player_queue[player_index] = game.tick  -- tick is used to check that the callback happens after X minutes as multiple callbacks may be active if the player logs off and on multiple times
            set_timeout_in_ticks(60, spawn_player_corpse, {player = player, tick = game.tick})
        end
    end
)