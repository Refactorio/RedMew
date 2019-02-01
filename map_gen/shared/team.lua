--[[
    This module creates and balances teams (forces) of players. It does not handle relationships between forces (ie. cease_fire and friend states).

    Balance is kept and maintained through several togglable event hooks:
    on_created: will assign new players to the lowest population team
    on_join: will assign new and returning players to the lowest population team
    on_leave: will find the highest population team, and if the difference between the highest population and lowest population team is 2 or more,
    a player from the highest population team will be sent to the lowest

    Examples

    -- Keeping 2 teams roughly balanced by assigning new players to the lowest population team
    -- Toggling the option of teleporting can be toggled on and off during runtime.
    local Teams = require 'map_gen.shared.team'
    Teams.set_event_teleporting(true) -- players will be teleported to their team's spawn when their team is changed via an event hook
    Teams.set_initial_num_of_teams(3) -- the number of teams to create at the beginning of the map
    Teams.enable_player_created_balancing() -- will assign new players to the lower population team
    Teams.set_team_names({'positive', 'negative', 'that third team'}) -- sets custom names for our 3 teams

    To act on players whose force/team has changed, use the on_player_changed_force event.
    To act on forces being created or merging, use the on_force_created, on_forces_merged, and on_forces_merging events.
    NB: There are many weird conditions around merging forces, check the API entries for the events as well as game.merge_forces
]]
-- Dependencies
local Global = require 'utils.global'
local Token = require 'utils.token'
local Event = require 'utils.event'
local Game = require 'utils.game'
local table = require 'utils.table'
local RS = require 'map_gen.shared.redmew_surface'
local Color = require 'resources.color_presets'
local Teamnames = require 'resources.team_names'

-- Localized functions
local format = string.format
local random = math.random
--local fast_remove = table.fast_remove
local remove_element = table.remove_element
local clear_table = table.clear_table
local contains = table.contains

-- Constants
-- 4 team names that will never be removed or added by this module
local always_protected_forces = {
    ['player'] = true,
    ['enemy'] = true,
    ['neutral'] = true,
    ['spectator'] = true,
    ['queue'] = true
}

-- Local vars
local Public = {}

-- Global register
local primitives = {
    teams_needed = 2,
    teleport = nil,
    on_join_balancing = nil,
    on_created_balancing = nil,
    on_leave_balancing = nil,
    --max_ppt = nil,
    --queue = nil
}
local team_store = {}
local team_names = {}
local protected_forces = {
    ['player'] = true,
    ['enemy'] = true,
    ['neutral'] = true,
    ['spectator'] = true,
    ['queue'] = true
}

Global.register(
    {
        primitives = primitives,
        team_store = team_store,
        team_names = team_names,
        protected_forces = protected_forces
    },
    function(tbl)
        primitives = tbl.primitives
        team_store = tbl.team_store
        team_names = tbl.team_names
        protected_forces = tbl.protected_forces
    end
)

--- Fills team_names until it reaches team_num entries
local function populate_team_names(teams_needed)
    for i = (#team_names + 1), teams_needed do
        local e_stop = 0
        local potential_name = Teamnames[random(#Teamnames)]
        while contains(team_names, potential_name) do
            potential_name = Teamnames[random(#Teamnames)]
            e_stop = e_stop + 1
            if e_stop > 500 then
                error('Stuck looking for unique team name for over 500 cycles')
                return
            end
        end
        team_names[i] = potential_name
    end
end

--- Checks if the provided team name can be merged or not
-- Specifically, check for an entry in protected_forces, or if it's the name of a team that is needed
-- @return <boolean>
local function is_protected_force(name, num_teams)
    if protected_forces[name] then
        return true
    end

    for i = 1, num_teams do
        if name == team_names[i] then
            return true
        end
    end
    return false
end

--- Edits the table of protected forces, removing/adding as directed by add_remove
-- The always_protected_forces members cannot be removed from the protected_forces table
-- Teams cannot be protected_forces as this would prevent set_requir
-- @param names <table> array of names
-- @param add_remove <boolean|nil> indicates whether to add to or remove from table
local function edit_protected_forces(names, add_remove)
    if not names then
        return
    end

    for i = 1, #names do
        local name = names[i]
        -- We don't allow the always_protected names nor team names to be added/removed from
        if not always_protected_forces[name] then
            protected_forces[name] = add_remove
        end
    end
end

--- Creates a new team based on the team_names array
local function create_team()
    local team_count = #team_store
    -- There can only be 61 custom forces, we keep 6 for a margin of error/spectator/for map use
    if team_count >= primitives.teams_needed or team_count >= 55 then
        return
    end

    local team_name = team_names[team_count + 1]
    local force = game.create_force(team_name)
    if not force or not force.valid then
        error('Force not created as expected or is invalid')
        return
    end

    team_store[team_count + 1] = force
    return force
end

--- Takes LuaPlayer and assigns them to LuaForce
local function assign_player(player, force)
    if player.force == force or not player.valid or not force.valid then
        return
    end

    force.print(format('%s has joined the team', player.name), Color.yellow)
    player.print('Welcome to your new team: ' .. force.name, Color.yellow)
    player.force = force
end

--- Tries to teleport a LuaPlayer to their force's spawn position
local function try_teleport_to_spawn(player)
    if primitives.teleport then
        local surface = RS.get_surface()
        local spawn_position = player.force.get_spawn_position(surface)
        local pos = surface.find_non_colliding_position('player', spawn_position, 200, 1)
        if not pos then
            player.print('Unable to find a place to teleport you to')
            log('No teleport position for player')
            return
        end

        player.teleport(pos, surface)
        player.print('You have been teleported to their spawn location', Color.yellow)
    end
end

--- Find the smallest of the teams and assign a player to it
-- @param player <LuaPlayer> the player to try to assign
local function find_team_for_player(player)
    local team_count = #team_store
    if team_count == 0 then
        player.print('No available positions on a team for you.')
        return
    end

    local smallest_team = team_store[1]
    for i = 2, team_count do
        local force = team_store[i]
        if not force.valid then
            error('Force invalid')
            return
        end

        if #force.connected_players < #smallest_team.connected_players then
            smallest_team = force
        end
    end
    assign_player(player, smallest_team)
    try_teleport_to_spawn(player)
end

--- Sets up the required number of teams, trimming forces that will no longer be needed
local function setup_required_teams()
    local teams_needed = primitives.teams_needed
    -- If we don't know how many teams we need, something went wrong.
    if not teams_needed then
        error('teams_needed is nil')
        return
    end

    -- We don't know if teams will have the same name when this is called
    -- so we check if the team should exist at the end of the setup
    for name, force in pairs(game.forces) do
        if not (is_protected_force(name, teams_needed)) then
            remove_element(team_store, force)
            game.merge_forces(name, 'player')
        end
    end

    -- Reset existing teams
    for i = 1, #team_store do
        team_store[i].reset()
    end

    -- Add required teams
    populate_team_names(teams_needed)
    while teams_needed > #team_store do
        create_team()
    end
end

--- Assigns new and/or returning players to the lowest population team.
local player_added =
    Token.register(
    function(event)
        local index = event.player_index
        if event.name == defines.events.on_player_created and primitives.on_join_balancing then
            return
        end

        local player = Game.get_player_by_index(index)
        if player and player.valid then
            find_team_for_player(player)
        end
    end
)

--- When a player leaves, check team populations differences. If found, compensate by bringing a player from a higher pop
-- team to the departing player's team
local player_left =
    Token.register(
    function(event)
        local player = Game.get_player_by_index(event.player_index)
        if not player then
            return
        end

        -- Setup gaining and losing forces
        local gforce = player.force
        local gforce_pcount = #gforce.connected_players
        local lforce

        for i = 1, #team_store do
            if (team_store[i].connected_players - gforce_pcount) > 1 then
                lforce = team_store[i]
                break
            end
        end

        if lforce then
            local transfer_player = lforce.connected_players[random(#lforce.connected_players)]
            assign_player(transfer_player, gforce)
            try_teleport_to_spawn(transfer_player)
        end
    end
)

local function register_player_created()
    Event.add_removable(defines.events.on_player_created, player_added)
end

local function register_player_joined()
    Event.add_removable(defines.events.on_player_joined_game, player_added)
end

local function register_player_left()
    Event.add_removable(defines.events.on_player_left_game, player_left)
end

-- Control stage event register

Event.on_init(setup_required_teams)

-- Public functions

--- Returns the forces assigned as teams
-- @return <table> returns an array of forces which represents the player teams
function Public.get_teams()
    return team_store
end

--- Sets the number of teams to keep players automatically balanced between
-- Can only be called pre-init, for a runtime option, see create_balanced_teams()
-- @param teams_needed <number> the number of teams
function Public.set_initial_num_of_teams(teams_needed)
    if teams_needed and teams_needed <= 55 then
        primitives.teams_needed = teams_needed
    else
        primitives.teams_needed = 55
    end
end

--- Sets whether or not to teleport players when they are assigned to a new team
-- Applied only to auto balancing/event-driven team assignments, not to create_balanced_teams
-- @param teleport <boolean>
function Public.set_event_teleporting(teleport)
    primitives.teleport = teleport
end

--- Clears the team_names table and fills it with entries from names
-- Can be called any time, will not rename existing teams
-- Team names cannot be protected forces, they will be ignored.
-- @param names <table> an array of strings
function Public.set_team_names(names)
    clear_table(team_names, true)
    for i = 1, #names do
        local name = names[i]

        if not protected_forces[name] then
            team_names[#team_names + 1] = name
        else
            game.print('WARNING: Registering the name of a protected force as a team name is not allowed', Color.red)
            log('WARNING: Registering the name of a protected force as a team name is not allowed')
        end
    end
end

--- Clears the team_names table.
function Public.clear_team_names()
    clear_table(team_names, true)
end

--- Adds names to the table of forces not to be deleted by setup_required_teams
-- @param names <table> array of names
function Public.add_protected_forces(names)
    edit_protected_forces(names, true)
end

--- Removes names from the table of forces not to be deleted by setup_required_teams
-- @param names <table> array of names
function Public.remove_protected_forces(names)
    edit_protected_forces(names)
end

--- Resets the protected forces table (to match the always_protected_forces table)
function Public.reset_protected_forces()
    for key in pairs(protected_forces) do
        if not always_protected_forces[key] then
            protected_forces[key] = nil
        end
    end
end

--- Registers the player_created event hook, assigning new players to the lowest population team
function Public.enable_player_created_balancing()
    if primitives.on_created_balancing then
        return
    end
    register_player_created()
    primitives.on_created_balancing = true
end

--- Unregisters the player_created event hook
function Public.disable_player_created_balancing()
    primitives.on_created_balancing = nil
    Event.remove_removable(defines.events.on_player_created, player_added)
end

--- Registers the player_join event hook, assigning new and returning players to the lowest population team
function Public.enable_join_balancing()
    if primitives.on_join_balancing then
        return
    end
    register_player_joined()
    primitives.on_join_balancing = true
end

--- Unregisters the player_join event hook
function Public.disable_join_balancing()
    primitives.on_join_balancing = nil
    Event.remove_removable(defines.events.on_player_joined_game, player_added)
end

--- Registers the player_left event hook, shuffling players if teams become imbalanced due to leaves
function Public.enable_leave_balancing()
    if primitives.on_leave_balancing then
        return
    end
    register_player_left()
    primitives.on_leave_balancing = true
end

--- Unregisters the left_game event hook
function Public.disable_leave_balancing()
    primitives.on_leave_balancing = nil
    Event.remove_removable(defines.events.on_player_left_game, player_left)
end

--[[
    WIP
--- Calling this will delete or reset all existing teams and create even teams based on the parameters supplied.
-- Can be called during or after init. (Should not be called during init as you have no players to assign...)
-- @param teams_min <number|nil> the minimum required teams, if nil is set to  2
-- @param teams_max <number|nil> the number of teams allowed, if nil is set to 55
-- @param per_team_min <number|nil> the minimum of players per team, if nil is set to 1
-- @param per_team_max <number|nil> the minimum of players per team, if nil is set to 100
-- @param absolute_balance <boolean> if false or nil, players will be assigned teams regardless of teams being imbalanced by 1
-- if true, players that cannot be placed into balanced teams will be returned as a table of LuaPlayers
-- @return <table> returns the array of teams or nil
function Public.create_balanced_teams(teams_min, teams_max, per_team_min, per_team_max, absolute_balance)
    teams_min = teams_min or 2
    teams_max = teams_max or 55
    per_team_min = per_team_min or 1
    per_team_max = per_team_max or 100
    primitives.max_ppt = per_team_max
    local players = game.connected_players
    local player_count = #players
    local num_teams
    local best_remainder

    if player_count < (teams_min * per_team_min) then
        game.print('Cannot create teams within parameters: too few players.', Color.yellow)
        return
    end

    for team_count = teams_min, teams_max do
        for ppt_count = per_team_min, per_team_max do
            if player_count == (team_count * ppt_count) then
                -- Plan A: easily divisible teams, everyone is happy
                num_teams = team_count
                absolute_balance = nil
                break
            elseif (player_count / (team_count * ppt_count)) > 1 then
                -- Plan B: no perfect factors, so we have a remainder
                local modulo = player_count % (team_count * ppt_count)
                if not best_remainder or best_remainder > modulo then
                    best_remainder = module
                    num_teams = team_count
                end
            end
        end
    end
    if num_teams then
        if num_teams < 2 then
            num_teams = 2
        end
        primitives.teams_needed = num_teams
        setup_required_teams()
        if absolute_balance then
            for i = 1, best_remainder do
                local remove_index = random(#players)
                fast_remove(players, remove_index)
            end
        end

        -- Move all players to the player force
        for _, player in pairs(players) do
            player.force = game.forces.player
        end
        -- With them all on the player force, we can now create balanced teams
        for _, player in pairs(players) do
            find_team_for_player(player)
        end

        return team_store
    else
        game.print('Unable to create teams', Color.yellow)
        log('Unable to create balanced teams')
        return
    end
end
]]
return Public
