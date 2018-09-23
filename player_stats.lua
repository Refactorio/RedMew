local Event = require 'utils.event'
local Global = require 'utils.global'
local Game = require 'utils.game'

local player_last_position = {}
local player_walk_distances = {}
local player_coin_earned = {}
local player_coin_spent = {}
local player_deaths = {}
local total_players = {0}

Global.register(
    {
        player_last_position = player_last_position,
        player_walk_distances = player_walk_distances,
        player_coin_earned = player_coin_earned,
        player_coin_spent = player_coin_spent,
        player_deaths = player_deaths,
        total_players = total_players
    },
    function(tbl)
        player_last_position = tbl.player_last_position
        player_walk_distances = tbl.player_walk_distances
        player_coin_earned = tbl.player_coin_earned
        player_coin_spent = tbl.player_coin_spent
        player_deaths = tbl.player_deaths
        total_players = tbl.total_players
    end
)

local function player_created(event)
    local index = event.player_index

    player_last_position[index] = Game.get_player_by_index(index).position
    player_walk_distances[index] = 0
    player_coin_earned[index] = 0
    player_coin_spent[index] = 0
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
end

local function picked_up_item(event)
    local stack = event.item_stack

    if stack.name == 'coin' then
        local player_index = event.player_index
        player_coin_earned[player_index] = player_coin_earned[player_index] + stack.count
    end
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

-- Returns a dictionary of casue_name -> count
function Public.get_all_death_counts_by_casue(player_index)
    return player_deaths[player_index].causes or {}
end

function Public.get_total_player_count()
    return total_players[1]
end

return Public
