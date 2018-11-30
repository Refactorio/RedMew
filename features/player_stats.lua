local Event = require 'utils.event'
local Global = require 'utils.global'
local Game = require 'utils.game'
local Server = require 'features.server'
local Token = require 'utils.token'
require 'utils.table'

local player_last_position = {}
local player_walk_distances = {}
local player_coin_earned = {}
local player_coin_spent = {}
local player_crafted_items = {}
local player_console_chats = {}
local player_damage_taken = {}
local player_damage_dealt = {}
local player_deaths = {}
local player_previous_session_playtime = {}
local player_other_map_playtime = {} -- all playtime on redmew maps excluding time on current map
local total_players = {0}
local total_train_kills = {0}
local total_trees_mined = {0}
local total_rocks_mined = {0}
local total_robot_built_entities = {0}
local total_player_built_entities = {0}

local train_kill_causes = {
    'locomotive',
    'cargo-wagon',
    'fluid-wagon',
    'artillery-wagon'
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
        total_trees_mined = total_trees_mined,
        total_rocks_mined = total_rocks_mined,
        player_crafted_items = player_crafted_items,
        player_console_chats = player_console_chats,
        player_damage_taken = player_damage_taken,
        player_damage_dealt = player_damage_dealt,
        total_robot_built_entities = total_robot_built_entities,
        player_other_map_playtime = player_other_map_playtime,
        total_player_built_entities = total_player_built_entities,
        player_previous_session_playtime = player_previous_session_playtime,
    },
    function(tbl)
        player_last_position = tbl.player_last_position
        player_walk_distances = tbl.player_walk_distances
        player_coin_earned = tbl.player_coin_earned
        player_coin_spent = tbl.player_coin_spent
        player_deaths = tbl.player_deaths
        total_players = tbl.total_players
        total_train_kills = tbl.total_train_kills
        total_trees_mined = tbl.total_trees_mined
        total_rocks_mined = tbl.total_rocks_mined
        player_crafted_items = tbl.player_crafted_items
        player_console_chats = tbl.player_console_chats
        player_damage_taken = tbl.player_damage_taken
        player_damage_dealt = tbl.player_damage_dealt
        total_robot_built_entities = tbl.total_robot_built_entities
        player_other_map_playtime = tbl.player_other_map_playtime
        total_player_built_entities = tbl.total_player_built_entities
        player_previous_session_playtime = tbl.player_previous_session_playtime
    end
)

--- When the player first logs on, initialize their stats and pull their former playtime
local function player_created(event)
    local index = event.player_index

    player_previous_session_playtime[index] = 0
    player_other_map_playtime[index] = 0
    player_last_position[index] = Game.get_player_by_index(index).position
    player_walk_distances[index] = 0
    player_coin_earned[index] = 0
    player_coin_spent[index] = 0
    player_crafted_items[index] = 0
    player_damage_taken[index] = 0
    player_damage_dealt[index] = 0
    player_deaths[index] = {causes = {}, count = 0}
    total_players[1] = total_players[1] + 1
end

local callback =
     Token.register(
     function(data)
         local key = data.key
         local value = data.value -- will be nil if no data
         local index = game.players[key].index
         local total_server_playtime = tonumber(value) or 0
         player_other_map_playtime[index] = total_server_playtime - player_previous_session_playtime[index]
     end
)

--- Returns total playtime on redmew: playtime on other maps + playtime on current map
local function calculate_player_total_playtime(index)
    local player = Game.get_player_by_index(index)
    return (player_other_map_playtime[index] + player.online_time)
end

local function player_joined_game(event)
    local index = event.player_index
    local player = Game.get_player_by_index(index)
    Server.try_get_data('total_playtime', player.name, callback)
end

local function player_left_game(event)
    local index = event.player_index
    local player = Game.get_player_by_index(index)
    Server.set_data('total_playtime', player.name, calculate_player_total_playtime(index))
    player_previous_session_playtime[index] = player.online_time
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

    if table.contains(train_kill_causes, cause) then
        total_train_kills = total_train_kills + 1
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
        total_rocks_mined[1] = total_rocks_mined[1] + 1
        return
    end
    if event.entity.type == 'tree' then
        total_trees_mined[1] = total_trees_mined[1] + 1
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

local function entity_damaged(event)
    if event.entity.type == 'player' then -- player taking damage
        local index = event.entity.player.index
        player_damage_taken[index] = player_damage_taken[index] + event.final_damage_amount
    end
    if event.cause.type == 'player' then -- player causing damage
        local index = event.cause.player.index
        player_damage_dealt[index] = player_damage_dealt[index] + event.final_damage_amount
    end
end

local function player_built_entity()
    total_player_built_entities[1] = total_player_built_entities[1] + 1
end

local function robot_built_entity()
    total_robot_built_entities[1] = total_robot_built_entities[1] + 1
end

local function tick()
    for _, p in ipairs(game.connected_players) do
        if (p.afk_time < 30 or p.walking_state.walking) and p.vehicle == nil then
            local index = p.index
            local last_pos = player_last_position[index]
            local pos = p.position

            local d_x = last_pos.x - pos.x
            local d_y = last_pos.y - pos.y

            player_walk_distances[index] = player_walk_distances[index] + math.sqrt(d_x * d_x + d_y * d_y)
            player_last_position[index] = pos
        end
    end
end

Event.add(defines.events.on_player_created, player_created)
Event.add(defines.events.on_player_died, player_died)
Event.add(defines.events.on_picked_up_item, picked_up_item)
Event.add(defines.events.on_pre_player_mined_item, player_mined_item)
Event.add(defines.events.on_player_crafted_item, player_crafted_item)
Event.add(defines.events.on_console_chat, player_console_chat)
Event.add(defines.events.on_entity_damaged, entity_damaged)
Event.add(defines.events.on_built_entity, player_built_entity)
Event.add(defines.events.on_robot_built_entity, robot_built_entity)
Event.add(defines.events.on_player_joined_game, player_joined_game)
Event.add(defines.events.on_player_left_game, player_left_game)

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
    player_coin_spent[player_index] = value
end

function Public.change_coin_spent(player_index, amount)
    player_coin_spent[player_index] = player_coin_spent[player_index] + amount
end

function Public.get_death_count(player_index)
    return player_deaths[player_index].count
end

-- Returns a dictionary of cause_name -> count
function Public.get_all_death_counts_by_casue(player_index)
    return player_deaths[player_index].causes or {}
end

-- Returns the amount of time the player spent on redmew before joining this map
function Public.get_player_other_map_playtime(player_index)
    return player_other_map_playtime[player_index]
end

-- Returns the amount of time the player spent on previous maps in addition to the current
function Public.get_player_total_playtime(player_index)
    return calculate_player_total_playtime(player_index)
end

function Public.get_total_player_count()
    return total_players[1]
end

function Public.get_total_train_kills()
    return total_train_kills[1]
end

function Public.get_total_trees_mined()
    return total_trees_mined[1]
end

function Public.get_total_rocks_mined()
    return total_rocks_mined[1]
end

function Public.get_player_crafted_item(player_index)
    return player_crafted_items[player_index]
end

function Public.get_player_console_chat(player_index)
    return player_console_chats[player_index]
end

function Public.get_player_damage_taken(player_index)
    return player_damage_taken[player_index]
end

function Public.get_player_damage_dealt(player_index)
    return player_damage_dealt[player_index]
end

function Public.get_total_robot_built_entities()
    return total_robot_built_entities[1]
end

return Public
