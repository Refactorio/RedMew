local Event = require 'utils.event'
local Global = require 'utils.global'
local Game = require 'utils.game'
require 'utils.table'
local pairs = pairs
local sqrt = math.sqrt

local player_last_position = {}
local player_walk_distances = {}
local player_coin_earned = {}
local player_coin_spent = {}
local player_crafted_items = {}
local player_console_chats = {}
local player_deaths = {}
local total_players = {0}
local total_train_kills = {0}
local total_player_trees_mined = {0}
local total_player_rocks_mined = {0}
local total_robot_built_entities = {0}
local total_player_built_entities = {0}
local total_biter_kills = {0}
local total_coins_spent = {0}

local train_kill_causes = {
    ['locomotive'] = true,
    ['cargo-wagon'] = true,
    ['fluid-wagon'] = true,
    ['artillery-wagon'] = true
}

Global.register(
    {
        player_last_position = player_last_position,
        player_walk_distances = player_walk_distances,
        player_coin_earned = player_coin_earned,
        player_coin_spent = player_coin_spent,
        player_deaths = player_deaths,
        total_players = total_players,
        total_train_kills = total_train_kills,
        total_player_trees_mined = total_player_trees_mined,
        total_player_rocks_mined = total_player_rocks_mined,
        player_crafted_items = player_crafted_items,
        player_console_chats = player_console_chats,
        total_robot_built_entities = total_robot_built_entities,
        total_player_built_entities = total_player_built_entities,
        total_biter_kills = total_biter_kills,
        total_coins_spent = total_coins_spent
    },
    function(tbl)
        player_last_position = tbl.player_last_position
        player_walk_distances = tbl.player_walk_distances
        player_coin_earned = tbl.player_coin_earned
        player_coin_spent = tbl.player_coin_spent
        player_deaths = tbl.player_deaths
        total_players = tbl.total_players
        total_train_kills = tbl.total_train_kills
        total_player_trees_mined = tbl.total_player_trees_mined
        total_player_rocks_mined = tbl.total_player_rocks_mined
        player_crafted_items = tbl.player_crafted_items
        player_console_chats = tbl.player_console_chats
        total_robot_built_entities = tbl.total_robot_built_entities
        total_player_built_entities = tbl.total_player_built_entities
        total_biter_kills = tbl.total_biter_kills
        total_coins_spent = tbl.total_coins_spent
    end
)

--- When the player first logs on, initialize their stats and pull their former playtime
local function player_created(event)
    local index = event.player_index

    player_last_position[index] = Game.get_player_by_index(index).position
    player_walk_distances[index] = 0
    player_coin_earned[index] = 0
    player_coin_spent[index] = 0
    player_crafted_items[index] = 0
    player_console_chats[index] = 0
    player_deaths[index] = {causes = {}, count = 0}
    total_players[1] = total_players[1] + 1
end

local function get_cause_name(cause)
    if cause then
        local name = cause.name
        if name == 'player' then
            local player = cause.player
            if player and player.valid then
                return player.name
            end
        else
            return name
        end
    end
    return 'No cause'
end

local function player_died(event)
    local player_index = event.player_index
    local cause = get_cause_name(event.cause)

    local data = player_deaths[player_index]
    data.count = data.count + 1

    local causes = data.causes
    local cause_count = causes[cause] or 0
    causes[cause] = cause_count + 1

    if train_kill_causes[cause] then
        total_train_kills[1] = total_train_kills[1] + 1
    end
end

local function picked_up_item(event)
    local stack = event.item_stack
    if stack.name == 'coin' then
        local player_index = event.player_index
        player_coin_earned[player_index] = player_coin_earned[player_index] + stack.count
    end
end

local function player_mined_item(event)
    if event.entity.type == 'simple-entity' then -- Cheap check for rock, may have other side effects
        total_player_rocks_mined[1] = total_player_rocks_mined[1] + 1
        return
    end
    if event.entity.type == 'tree' then
        total_player_trees_mined[1] = total_player_trees_mined[1] + 1
    end
end

local function player_crafted_item(event)
    local stack = event.item_stack
    local player_index = event.player_index
    player_crafted_items[player_index] = player_crafted_items[player_index] + stack.count
end

local function player_console_chat(event)
    local player_index = event.player_index
    if player_index then
        player_console_chats[player_index] = player_console_chats[player_index] + 1
    end
end

local function player_built_entity()
    total_player_built_entities[1] = total_player_built_entities[1] + 1
end

local function robot_built_entity()
    total_robot_built_entities[1] = total_robot_built_entities[1] + 1
end

local function biter_kill_counter(event)
    if event.entity.force.name == 'enemy' then
        total_biter_kills[1] = total_biter_kills[1] + 1
    end
end

local function tick()
    for _, p in pairs(game.connected_players) do
        if (p.afk_time < 30 or p.walking_state.walking) and p.vehicle == nil then
            local index = p.index
            local last_pos = player_last_position[index]
            local pos = p.position

            local d_x = last_pos.x - pos.x
            local d_y = last_pos.y - pos.y

            player_walk_distances[index] = player_walk_distances[index] + sqrt(d_x * d_x + d_y * d_y)
            player_last_position[index] = pos
        end
    end
end

Event.add(defines.events.on_player_created, player_created)
Event.add(defines.events.on_player_died, player_died)
Event.add(defines.events.on_player_mined_item, picked_up_item)
Event.add(defines.events.on_picked_up_item, picked_up_item)
Event.add(defines.events.on_pre_player_mined_item, player_mined_item)
Event.add(defines.events.on_player_crafted_item, player_crafted_item)
Event.add(defines.events.on_console_chat, player_console_chat)
Event.add(defines.events.on_built_entity, player_built_entity)
Event.add(defines.events.on_robot_built_entity, robot_built_entity)
Event.add(defines.events.on_entity_died, biter_kill_counter)

Event.on_nth_tick(62, tick)

local Public = {}

function Public.get_walk_distance(player_index)
    return player_walk_distances[player_index]
end

function Public.get_coin_earned(player_index)
    return player_coin_earned[player_index]
end

function Public.set_coin_earned(player_index, value)
    player_coin_earned[player_index] = value
end

function Public.change_coin_earned(player_index, amount)
    player_coin_earned[player_index] = player_coin_earned[player_index] + amount
end

function Public.get_coin_spent(player_index)
    return player_coin_spent[player_index]
end

function Public.set_coin_spent(player_index, value)
    local old_value = player_coin_spent[player_index]
    player_coin_spent[player_index] = value

    local diff = value - old_value
    total_coins_spent[1] = total_coins_spent[1] + diff
end

function Public.change_coin_spent(player_index, amount)
    player_coin_spent[player_index] = player_coin_spent[player_index] + amount
    total_coins_spent[1] = total_coins_spent[1] + amount
end

function Public.get_death_count(player_index)
    return player_deaths[player_index].count
end

function Public.get_crafted_item(player_index)
    return player_crafted_items[player_index]
end

function Public.get_console_chat(player_index)
    return player_console_chats[player_index]
end

-- Returns a dictionary of cause_name -> count
function Public.get_all_death_counts_by_cause(player_index)
    return player_deaths[player_index].causes or {}
end

function Public.get_total_player_count()
    return total_players[1]
end

function Public.get_total_train_kills()
    return total_train_kills[1]
end

function Public.get_total_player_trees_mined()
    return total_player_trees_mined[1]
end

function Public.get_total_player_rocks_mined()
    return total_player_rocks_mined[1]
end

function Public.get_total_robot_built_entities()
    return total_robot_built_entities[1]
end

function Public.get_total_player_built_entities()
    return total_player_built_entities[1]
end

function Public.get_total_biter_kills()
    return total_biter_kills[1]
end

function Public.get_total_coins_spent()
    return total_coins_spent[1]
end

return Public
