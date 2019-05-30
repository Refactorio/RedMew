local Event = require 'utils.event'
local Global = require 'utils.global'
local ScoreTracker = require 'utils.score_tracker'
require 'utils.table'
local pairs = pairs
local sqrt = math.sqrt

local rocks_smashed_name = 'rocks-smashed'
local trees_cut_name = 'trees-cut'
local player_count_name = 'player-count'
local kills_by_trains_name = 'kills-by-trains'
local built_by_robots_name = 'built-by-robots'
local built_by_players_name = 'built-by-players'
local aliens_killed_name = 'aliens-killed'
local coins_spent_name = 'coins-spent'
local coins_earned_name = 'coins-earned'
local player_deaths_name = 'player-deaths'
local player_console_chats_name = 'player-console-chats'
local player_items_crafted_name = 'player-items-crafted'
local player_distance_walked_name = 'player-distance_walked'

ScoreTracker.register(rocks_smashed_name, {'Rocks smashed'}, '[img=entity.rock-huge]')
ScoreTracker.register(trees_cut_name, {'Trees cut down'}, '[img=entity.tree-02]')
ScoreTracker.register(player_count_name, {'Total players'})
ScoreTracker.register(kills_by_trains_name, {'Kills by trains'}, '[img=item.locomotive]')
ScoreTracker.register(built_by_players_name, {'Built by hand'}, '[img=utility.hand]')
ScoreTracker.register(built_by_robots_name, {'Built by robots'}, '[img=item.construction-robot]')
ScoreTracker.register(aliens_killed_name, {'Aliens liberated'}, '[img=entity.medium-biter]')
ScoreTracker.register(coins_earned_name, {'Coins earned'}, '[img=item.coin]')
ScoreTracker.register(coins_spent_name, {'Coins spent'}, '[img=item.coin]')
ScoreTracker.register(player_deaths_name, {'Player deaths'})
ScoreTracker.register(player_console_chats_name, {'Player console chats'})
ScoreTracker.register(player_items_crafted_name, {'Player items crafted'})
ScoreTracker.register(player_distance_walked_name, {'Player distance walked'})

local player_last_position = {}
local player_death_causes = {}

local train_kill_causes = {
    ['locomotive'] = true,
    ['cargo-wagon'] = true,
    ['fluid-wagon'] = true,
    ['artillery-wagon'] = true
}

Global.register(
    {
        player_last_position = player_last_position,
        player_death_causes = player_death_causes,
    },
    function(tbl)
        player_last_position = tbl.player_last_position
        player_death_causes = tbl.player_death_causes
    end
)

--- When the player first logs on, initialize their stats and pull their former playtime
local function player_created(event)
    local index = event.player_index

    player_last_position[index] = game.get_player(index).position
    player_death_causes[index] = {}
    ScoreTracker.changeForGlobal(player_count_name, 1)
end

local function get_cause_name(cause)
    if cause then
        local name = cause.name
        if name == 'character' then
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

    local causes = player_death_causes[player_index]
    local cause_count = causes[cause] or 0
    causes[cause] = cause_count + 1

    ScoreTracker.changeForPlayer(player_index, player_deaths_name, 1)
    if train_kill_causes[cause] then
        ScoreTracker.changeForGlobal(kills_by_trains_name, 1)
    end
end

local function picked_up_item(event)
    local stack = event.item_stack
    if stack.name == 'coin' then
        ScoreTracker.changeForPlayer(event.player_index, coins_earned_name, stack.count)
    end
end

local function player_mined_item(event)
    if event.entity.type == 'simple-entity' then -- Cheap check for rock, may have other side effects
        ScoreTracker.changeForGlobal(rocks_smashed_name, 1)
        return
    end
    if event.entity.type == 'tree' then
        ScoreTracker.changeForGlobal(trees_cut_name, 1)
    end
end

local function player_crafted_item(event)
    ScoreTracker.changeForPlayer(event.player_index, player_items_crafted_name, event.item_stack.count)
end

local function player_console_chat(event)
    local player_index = event.player_index
    if player_index then
        ScoreTracker.changeForPlayer(player_index, player_console_chats_name, 1)
    end
end

local function player_built_entity()
    ScoreTracker.changeForGlobal(built_by_players_name, 1)
end

local function robot_built_entity()
    ScoreTracker.changeForGlobal(built_by_robots_name, 1)
end

local function biter_kill_counter(event)
    if event.entity.force.name == 'enemy' then
        ScoreTracker.changeForGlobal(aliens_killed_name, 1)
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

            player_last_position[index] = pos
            ScoreTracker.changeForPlayer(index, player_distance_walked_name, sqrt(d_x * d_x + d_y * d_y))
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
    return ScoreTracker.getForPlayer(player_index, player_distance_walked_name)
end

function Public.get_coin_earned(player_index)
    return ScoreTracker.getForPlayer(player_index, coins_earned_name)
end

function Public.change_coin_earned(player_index, amount)
    ScoreTracker.changeForPlayer(player_index, coins_earned_name, amount)
end

function Public.get_coin_spent(player_index)
    return ScoreTracker.getForPlayer(player_index, coins_spent_name)
end

function Public.change_coin_spent(player_index, amount)
    ScoreTracker.changeForPlayer(player_index, coins_spent_name, amount)
    ScoreTracker.changeForGlobal(coins_spent_name, amount)
end

function Public.get_death_count(player_index)
    return ScoreTracker.getForPlayer(player_index, player_deaths_name)
end

function Public.get_crafted_item(player_index)
    return ScoreTracker.getForPlayer(player_index, player_items_crafted_name)
end

function Public.get_console_chat(player_index)
    return ScoreTracker.getForPlayer(player_index, player_console_chats_name)
end

-- Returns a dictionary of cause_name -> count
function Public.get_all_death_causes_by_player(player_index)
    return player_death_causes[player_index] or {}
end

function Public.get_total_player_count()
    return ScoreTracker.getForGlobal(player_count_name)
end

function Public.get_total_train_kills()
    return ScoreTracker.getForGlobal(kills_by_trains_name)
end

function Public.get_total_player_trees_mined()
    return ScoreTracker.getForGlobal(trees_cut_name)
end

function Public.get_total_player_rocks_mined()
    return ScoreTracker.getForGlobal(rocks_smashed_name)
end

function Public.get_total_robot_built_entities()
    return ScoreTracker.getForGlobal(built_by_robots_name)
end

function Public.get_total_player_built_entities()
    return ScoreTracker.getForGlobal(built_by_players_name)
end

function Public.get_total_biter_kills()
    return ScoreTracker.getForGlobal(aliens_killed_name)
end

function Public.get_total_coins_spent()
    return ScoreTracker.getForGlobal(coins_spent_name)
end

return Public
