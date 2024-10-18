-- This feature allows you to turn on anti-hoarding so that X minutes after a player leaves the game
-- the resources in their inventory are returned to the teams. A corpse will spawn on the player's last
-- position and remain until they log back in to claim it or someone else mines it.
-- All players will drop their armors and weapons during the first 24h of the game,
-- after this time, only regulars and above will keep their armor and just drop the inventory.
local Event = require 'utils.event'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Global = require 'utils.global'
local CorpseUtil = require 'features.corpse_util'
local Config = require 'config'
local Rank = require 'features.rank_system'
local Ranks = require 'resources.ranks'
local MINS_TO_TICKS = 60 * 60
local HOUR_TO_TICKS = MINS_TO_TICKS * 60
local DEFAULT_OFFLINE_TIMEOUT_MINS = 15
local DEFAULT_STARTUP_GEAR_DROP_HOURS = 24

local set_timeout_in_ticks = Task.set_timeout_in_ticks
local config = Config.dump_offline_inventories

local offline_player_queue = {}

Global.register({offline_player_queue = offline_player_queue}, function(tbl)
    offline_player_queue = tbl.offline_player_queue
    config = Config.dump_offline_inventories
end)

local function spawn_player_corpse(player, banned, timeout_minutes)
    local player_index = player.index
    offline_player_queue[player_index] = nil

    if not banned and player.connected then
        return
    end

    local inventory_types = {
        defines.inventory.character_main,
        defines.inventory.character_guns,
        defines.inventory.character_ammo,
        defines.inventory.character_vehicle,
        defines.inventory.character_trash,
    }

    local startup_gear_drop_hours = config.startup_gear_drop_hours or DEFAULT_STARTUP_GEAR_DROP_HOURS
    if banned or game.tick < (startup_gear_drop_hours * HOUR_TO_TICKS) or Rank.less_than(player.name, Ranks.regular) then
        table.insert(inventory_types, defines.inventory.character_armor)
    end

    local inv_contents = {}
    for _, id in pairs(inventory_types)  do
        local inv = player.get_inventory(id)
        if inv and inv.valid then
            for i = 1, #inv do
                local item_stack = inv[i]
                if item_stack.valid_for_read then
                    table.insert(inv_contents, item_stack)
                end
            end
        end
    end

    if #inv_contents == 0 then
        return
    end

    local position = player.physical_position
    local corpse = player.physical_surface.create_entity {
        name = 'character-corpse',
        position = position,
        inventory_size = #inv_contents,
        player_index = player_index
    }
    corpse.active = false

    local inv_corpse = corpse.get_inventory(defines.inventory.character_corpse)
    for _, item_stack in pairs(inv_contents) do
        inv_corpse.insert(item_stack)
    end

    for _, id in pairs(inventory_types)  do
        local inv = player.get_inventory(id)
        if inv and inv.valid then
            inv.clear()
        end
    end

    local text = player.name .. "'s inventory (offline)"
    local tag = player.force.add_chart_tag(player.surface, {
        icon = {type = 'item', name = 'modular-armor'},
        position = position,
        text = text
    })

    local message
    if banned then
        message = {
            'dump_offline_inventories.banned_inventory_location',
            player.name,
            string.format('%.1f', position.x),
            string.format('%.1f', position.y),
            player.surface.name
        }
    else
        message = {
            'dump_offline_inventories.inventory_location',
            player.name,
            timeout_minutes,
            string.format('%.1f', position.x),
            string.format('%.1f', position.y),
            player.surface.name
        }
    end

    game.print(message)

    if tag then
        CorpseUtil.add_tag(tag, player_index, game.tick, false)
    end
end

local spawn_player_corpse_token = Token.register(function(data)
    local player = data.player
    if not player or not player.valid then
        return
    end

    local queue_data = offline_player_queue[player.index]
    if queue_data ~= data.tick then
        return
    end

    spawn_player_corpse(player, false, data.timeout_minutes)
end)

local function start_timer(event, timeout_minutes)
    local player_index = event.player_index
    local player = game.get_player(player_index)

    if player and player.valid and player.character then -- if player leaves before respawning they wont have a character and we don't need to add them to the list.
        local tick = game.tick
        local timeout = timeout_minutes * MINS_TO_TICKS

        offline_player_queue[player_index] = tick -- tick is used to check that the callback happens after X minutes as multiple callbacks may be active if the player logs off and on multiple times
        set_timeout_in_ticks(timeout, spawn_player_corpse_token,
            {player = player, tick = tick, timeout_minutes = timeout_minutes})
    end
end

Event.add(defines.events.on_pre_player_left_game, function(event)
    if not config.enabled then
        return
    end

    start_timer(event, config.offline_timeout_mins or DEFAULT_OFFLINE_TIMEOUT_MINS)
end)

Event.add(defines.events.on_player_banned, function(event)
    local player_index = event.player_index
    if not player_index then
        return
    end

    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    spawn_player_corpse(player, true, 0)
end)
