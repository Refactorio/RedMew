local Global = require 'utils.global'
local Event = require 'utils.event'
local ScoreTracker = require 'utils.score_tracker'
require 'utils.table'
local pairs = pairs
local sqrt = math.sqrt
local change_for_global = ScoreTracker.change_for_global
local change_for_player = ScoreTracker.change_for_player

local rocks_smashed_name = 'rocks-smashed'
local trees_cut_down_name = 'trees-cut'
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
local player_distance_walked_name = 'player-distance-walked'
local satellites_launched_name = 'satellites-launched'

ScoreTracker.register(rocks_smashed_name, {'player_stats.rocks_smashed'}, '[img=entity.rock-huge]')
ScoreTracker.register(trees_cut_down_name, {'player_stats.trees_cut_down'}, '[img=entity.tree-02]')
ScoreTracker.register(player_count_name, {'player_stats.player_count'})
ScoreTracker.register(kills_by_trains_name, {'player_stats.kills_by_trains'}, '[img=item.locomotive]')
ScoreTracker.register(built_by_players_name, {'player_stats.built_by_players'}, '[img=utility.hand]')
ScoreTracker.register(built_by_robots_name, {'player_stats.built_by_robots'}, '[img=item.construction-robot]')
ScoreTracker.register(aliens_killed_name, {'player_stats.aliens_killed'}, '[img=entity.medium-biter]')
ScoreTracker.register(coins_earned_name, {'player_stats.coins_earned'}, '[img=item.coin]')
ScoreTracker.register(coins_spent_name, {'player_stats.coins_spent'}, '[img=item.coin]')
ScoreTracker.register(player_deaths_name, {'player_stats.player_deaths'})
ScoreTracker.register(player_console_chats_name, {'player_stats.player_console_chats'})
ScoreTracker.register(player_items_crafted_name, {'player_stats.player_items_crafted'})
ScoreTracker.register(player_distance_walked_name, {'player_stats.player_distance_walked'})
ScoreTracker.register(satellites_launched_name, {'player_stats.satellites_launched'}, '[img=item.satellite]')

local train_kill_causes = {
    ['locomotive'] = true,
    ['cargo-wagon'] = true,
    ['fluid-wagon'] = true,
    ['artillery-wagon'] = true
}

local player_last_position = {}
local player_death_causes = {}

Global.register(
    {
        player_last_position = player_last_position,
        player_death_causes = player_death_causes
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
    change_for_global(player_count_name, 1)
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
    return 'player_stats.unknown_death_cause'
end

local function player_died(event)
    local player_index = event.player_index
    local cause = get_cause_name(event.cause)

    local causes = player_death_causes[player_index]
    local cause_count = causes[cause] or 0
    causes[cause] = cause_count + 1

    change_for_player(player_index, player_deaths_name, 1)
    if train_kill_causes[cause] then
        change_for_global(kills_by_trains_name, 1)
    end
end

local function picked_up_item(event)
    local stack = event.item_stack
    if stack.name == 'coin' then
        change_for_player(event.player_index, coins_earned_name, stack.count)
    end
end

local function player_mined_item(event)
    if event.entity.type == 'simple-entity' then -- Cheap check for rock, may have other side effects
        change_for_global(rocks_smashed_name, 1)
        return
    end
    if event.entity.type == 'tree' then
        change_for_global(trees_cut_down_name, 1)
    end
end

local function player_crafted_item(event)
    change_for_player(event.player_index, player_items_crafted_name, event.item_stack.count)
end

local function player_console_chat(event)
    local player_index = event.player_index
    if player_index then
        change_for_player(player_index, player_console_chats_name, 1)
    end
end

local function player_built_entity()
    change_for_global(built_by_players_name, 1)
end

local function robot_built_entity()
    change_for_global(built_by_robots_name, 1)
end

local function biter_kill_counter(event)
    if event.entity.force.name == 'enemy' then
        change_for_global(aliens_killed_name, 1)
    end
end

local function rocket_launched(event)
    local entity = event.rocket

    if not entity or not entity.valid or not entity.force == 'player' then
        return
    end

    local inventory = entity.get_inventory(defines.inventory.rocket)
    if not inventory or not inventory.valid then
        return
    end

    local count = inventory.get_item_count('satellite')
    if count == 0 then
        return
    end

    change_for_global(satellites_launched_name, 1)
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
            change_for_player(index, player_distance_walked_name, sqrt(d_x * d_x + d_y * d_y))
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
Event.add(defines.events.on_rocket_launched, rocket_launched)

Event.on_nth_tick(62, tick)

local Public = {}

-- Returns a dictionary of cause_name -> count
function Public.get_all_death_causes_by_player(player_index)
    return player_death_causes[player_index] or {}
end

return Public
