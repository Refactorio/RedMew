local Global = require 'utils.global'
local Event = require 'utils.event'
local Rocket = require 'utils.rocket'
local SA = require 'utils.space_age'
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
local rockets_launched_name = 'rockets-launched'
local player_units_killed_name = 'player-units-killed' -- biters and spitters
local player_worms_killed_name = 'player-worms-killed'
local player_spawners_killed_name = 'player-spawners-killed'
local player_total_kills_name = 'player-total-kills'
local player_turrets_killed_name = 'player-turrets-killed'
local player_entities_built_name = 'player_entities_built'
local player_fish_eaten_name = 'player_fish_eaten'
local player_resources_hand_mined_name = 'player_resources_hand_mined'
local resources_hand_mined_name = 'resources_hand_mined'
local resources_exhausted_name = 'resources_exhausted'

ScoreTracker.register(rocks_smashed_name, {'player_stats.rocks_smashed'}, '[img=entity.huge-rock]')
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
if not SA.enabled() then
    ScoreTracker.register(satellites_launched_name, {'player_stats.satellites_launched'}, '[img=item.satellite]')
end
ScoreTracker.register(rockets_launched_name, {'player_stats.rockets_launched'}, '[img=item.rocket-silo]')
ScoreTracker.register(player_units_killed_name, {'player_stats.player_units_killed'})
ScoreTracker.register(player_worms_killed_name, {'player_stats.player_worms_killed'})
ScoreTracker.register(player_spawners_killed_name, {'player_stats.player_spawners_killed'})
ScoreTracker.register(player_turrets_killed_name, {'player_stats.player_turrets_killed'})
ScoreTracker.register(player_total_kills_name, {'player_stats.player_total_kills'})
ScoreTracker.register(player_entities_built_name, {'player_stats.player_entities_built'})
ScoreTracker.register(player_fish_eaten_name, {'player_stats.player_fish_eaten'})
ScoreTracker.register(player_resources_hand_mined_name, {'player_stats.player_resources_hand_mined'})
ScoreTracker.register(resources_hand_mined_name, {'player_stats.resources_hand_mined'})
ScoreTracker.register(resources_exhausted_name, {'player_stats.resources_exhausted'})

local train_kill_causes = {
    ['locomotive'] = true,
    ['cargo-wagon'] = true,
    ['fluid-wagon'] = true,
    ['artillery-wagon'] = true
}

local entity_to_category_map = {
    -- spawners
    ['biter-spawner'] = player_spawners_killed_name,
    ['spitter-spawner'] = player_spawners_killed_name,

    -- worms
    ['small-worm-turret'] = player_worms_killed_name,
    ['medium-worm-turret'] = player_worms_killed_name,
    ['big-worm-turret'] = player_worms_killed_name,
    ['behemoth-worm-turret'] = player_worms_killed_name,

    -- units
    ['small-biter'] = player_units_killed_name,
    ['medium-biter'] = player_units_killed_name,
    ['big-biter'] = player_units_killed_name,
    ['behemoth-biter'] = player_units_killed_name,
    ['small-spitter'] = player_units_killed_name,
    ['medium-spitter'] = player_units_killed_name,
    ['big-spitter'] = player_units_killed_name,
    ['behemoth-spitter'] = player_units_killed_name,

    -- turrets
    ['gun-turret'] = player_turrets_killed_name,
    ['laser-turret'] = player_turrets_killed_name,
    ['artillery-turret'] = player_turrets_killed_name,
    ['flamethrower-turret'] = player_turrets_killed_name,

    -- others
    ['defender'] = false,
    ['distractor'] = false,
    ['destroyer'] = false
}

local player_last_position = {}
local player_death_causes = {}

Global.register({player_last_position = player_last_position, player_death_causes = player_death_causes}, function(tbl)
    player_last_position = tbl.player_last_position
    player_death_causes = tbl.player_death_causes
end)

--- When the player first logs on, initialize their stats and pull their former playtime
local function player_created(event)
    local index = event.player_index

    player_last_position[index] = game.get_player(index).physical_position
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

local function pre_player_mined_item(event)
    local entity = event.entity
    if entity.type == 'simple-entity' then -- Cheap check for rock, may have other side effects
        change_for_global(rocks_smashed_name, 1)
        return
    end
    if entity.type == 'resource' then
        change_for_global(resources_hand_mined_name, 1)
        change_for_player(event.player_index, player_resources_hand_mined_name, 1)
    end
    if entity.type == 'tree' then
        change_for_global(trees_cut_down_name, 1)
        return
    end
    if entity.type == 'container'  and entity.operable == false then -- We check the container is not operable as these are used as loot chests in Crash Site and players can't add coins to them.
        local inv = entity.get_inventory(defines.inventory.chest)
        local coin_count = inv.get_item_count("coin")
        if coin_count then
            change_for_player(event.player_index, coins_earned_name, coin_count)
        end
    end
end

local function resource_depleted(event)
    local entity = event.entity
    if entity.amount == 0 then
        change_for_global(resources_exhausted_name, 1)
    end
end

local function player_crafted_item(event)
    local item_stack = event.item_stack
    if not item_stack or not item_stack.valid_for_read then
        return
    end

    change_for_player(event.player_index, player_items_crafted_name, item_stack.count)
end

local function player_console_chat(event)
    local player_index = event.player_index
    if player_index then
        change_for_player(player_index, player_console_chats_name, 1)
    end
end

local function player_built_entity(event)
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    local player_index = event.player_index
    if entity.is_registered_for_construction() == false then -- When is_registered_for_construction() is true we only register the entity as built once a robot builds it
        change_for_global(built_by_players_name, 1)
        change_for_player(player_index, player_entities_built_name, 1)
    end
end

local function robot_built_entity(event)
    change_for_global(built_by_robots_name, 1)
    local robot = event.robot

    if not robot.valid then
        return
    end

    -- When item gets built, add to the total entities built for the player whose robot built the entity NOT for the player who placed the ghost
    local robot_owner = robot.logistic_network.cells[1].owner
    if robot_owner.name == 'character' and robot_owner.player then  -- nil if the robot owner is a roboport
        change_for_player(robot_owner.player.index, player_entities_built_name, 1)
    end
end

local function get_player_index_from_cause(cause, event)
    if cause.name == 'character' then
        return cause.player.index
    end

    local cause_type = cause.type
    if cause_type ~= 'car' and cause_type ~= 'spider-vehicle' then
        return nil
    end

    local driver = cause.get_driver()
    local passenger = cause.get_passenger()
    if not driver and not passenger then
        return nil -- for empty vehicle
    end

    local damage_type = event.damage_type.name
    local spidertron_targetting_paramers = false
    if cause_type == 'spider-vehicle' then
        spidertron_targetting_paramers = cause.vehicle_automatic_targeting_parameters.auto_target_with_gunner -- if targetting is automatic then the driver gets the kill unless they're not in the spider
    end

    if damage_type == 'impact' then -- damage type is impact when a vehicle runs over an entity
        if driver then -- to check if the driver jumped out before the kill
            return driver.player.index
        end

        return nil
    end

    if not passenger then
        return driver.player.index
    end

    if driver and (cause.driver_is_gunner or spidertron_targetting_paramers) then -- the if driver allows autotarget kills to go to the passenger when they're in spidertron
        return driver.player.index
    else
        return passenger.player.index
    end
end

local function entity_died(event)
    local entity = event.entity
    if not entity or not entity.valid or entity.force.name ~= 'enemy' then
        return
    end

    change_for_global(aliens_killed_name, 1)

    local cause = event.cause
    if not cause or not cause.valid then
        return
    end

    -- Only store for players if its an allowed entity (ie not for walls, chests etc)
    local category = entity_to_category_map[entity.name]
    if category == nil then
        return
    end

    local player_index = get_player_index_from_cause(cause, event)
    if player_index then
        change_for_player(player_index, player_total_kills_name, 1)
        if category then
            change_for_player(player_index, category, 1)
        end
    end
end

local function rocket_launched(event)
    local entity = event.rocket

    if not entity or not entity.valid or not entity.force == 'player' then
        return
    end

    change_for_global(rockets_launched_name, 1)

    if 0 == Rocket.count_rocket_contents(entity.cargo_pod, { name = 'satellite' }) then
        return
    end

    change_for_global(satellites_launched_name, 1)
end

local function capsule_used(event)
    local item = event.item

    if not item or not item.valid or item.name ~= 'raw-fish' then
        return
    end

    change_for_player(event.player_index, player_fish_eaten_name, 1)
end
local function tick()
    for _, p in pairs(game.connected_players) do
        if (p.afk_time < 30 or p.walking_state.walking) and p.vehicle == nil then
            local index = p.index
            local last_pos = player_last_position[index]
            local pos = p.physical_position

            local d_x = last_pos.x - pos.x
            local d_y = last_pos.y - pos.y

            player_last_position[index] = pos
            change_for_player(index, player_distance_walked_name, sqrt(d_x * d_x + d_y * d_y))
        end
    end
end

Event.add(defines.events.on_player_created, player_created)
Event.add(defines.events.on_player_died, player_died)
Event.add(defines.events.on_picked_up_item, picked_up_item)
Event.add(defines.events.on_pre_player_mined_item, pre_player_mined_item)
Event.add(defines.events.on_player_crafted_item, player_crafted_item)
Event.add(defines.events.on_console_chat, player_console_chat)
Event.add(defines.events.on_built_entity, player_built_entity)
Event.add(defines.events.on_robot_built_entity, robot_built_entity)
Event.add(defines.events.on_entity_died, entity_died)
Event.add(defines.events.on_rocket_launched, rocket_launched)
Event.add(defines.events.on_player_used_capsule, capsule_used)
Event.add(defines.events.on_resource_depleted, resource_depleted)

Event.on_nth_tick(62, tick)

local Public = {
    rocks_smashed_name = rocks_smashed_name,
    trees_cut_down_name = trees_cut_down_name,
    player_count_name = player_count_name,
    kills_by_trains_name = kills_by_trains_name,
    built_by_robots_name = built_by_robots_name,
    built_by_players_name = built_by_players_name,
    aliens_killed_name = aliens_killed_name,
    coins_spent_name = coins_spent_name,
    coins_earned_name = coins_earned_name,
    player_deaths_name = player_deaths_name,
    player_console_chats_name = player_console_chats_name,
    player_items_crafted_name = player_items_crafted_name,
    player_distance_walked_name = player_distance_walked_name,
    rockets_launched_name = rockets_launched_name,
    satellites_launched_name = satellites_launched_name,
    player_units_killed_name = player_units_killed_name,
    player_worms_killed_name = player_worms_killed_name,
    player_spawners_killed_name = player_spawners_killed_name,
    player_total_kills_name = player_total_kills_name,
    player_turrets_killed_name = player_turrets_killed_name,
    player_entities_built_name = player_entities_built_name,
    player_fish_eaten_name = player_fish_eaten_name,
    player_resources_hand_mined_name = player_resources_hand_mined_name,
    resources_hand_mined_name = resources_hand_mined_name,
    resources_exhausted_name = resources_exhausted_name
}

-- Returns a dictionary of cause_name -> count
function Public.get_all_death_causes_by_player(player_index)
    return player_death_causes[player_index] or {}
end

return Public
