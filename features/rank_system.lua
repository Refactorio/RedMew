--[[
    This rank system is meant to allow for easy addition or removal of ranks from the heirarchy.
    Ranks can be freely modified in resources.ranks as all the relation of the ranks to one another is all that matters.

    While all the public functions want rank as a number, modules should use references to resources.ranks and not have actual numbers.
    To dissuade the use of numeric ranks, there is explicitly no get_rank function.
    Ex: right way: Rank.equal(player_name, Rank.regular) wrong way: Rank.equal(player_name, 2)
]]
-- Dependencies
local Event = require 'utils.event'
local Game = require 'utils.game'
local Global = require 'utils.global'
local table = require 'utils.table'
local Token = require 'utils.token'
local math = require 'utils.math'
local Server = require 'features.server'
local Ranks = require 'resources.ranks'
local Colors = require 'resources.color_presets'

local config = global.config.rank_system
local trust_time = config.time_for_trust
local everyone_is_regular = config.everyone_is_regular

-- Localized functions
local clamp = math.clamp
local clear_table = table.clear_table

-- Constants
local ranking_data_set = 'rankings'
local nth_tick = 54001 -- nearest prime to 15 minutes in ticks
local rank_name_lookup = {}
local sorted_ranks = {}
local rank_to_index = {}

for k, v in pairs(Ranks) do
    rank_name_lookup[v] = {'ranks.' .. k}
end
for k, v in pairs(Ranks) do
    sorted_ranks[#sorted_ranks + 1] = v
end
table.sort(sorted_ranks)

for k, v in pairs(sorted_ranks) do
    rank_to_index[v] = k
end

-- Local vars
local Public = {}
local set_player_rank

-- Global register vars
local player_ranks = {}
local guests = {}

Global.register(
    {
        player_ranks = player_ranks,
        guests = guests
    },
    function(tbl)
        player_ranks = tbl.player_ranks
        guests = tbl.guests
    end
)

-- Local functions

--- Changes a rank by a fixed number
-- @param current_rank <number>
-- @param change <number> the number by which to increase or decrease a rank
local function change_rank_by_number(current_rank, change)
    local index = rank_to_index[current_rank]

    local new_index = clamp(index + change, 1, #sorted_ranks)

    return sorted_ranks[new_index]
end

--- Check each online player and if their playtime is above the required cutoff, promote them to auto-trusted.
-- Only applies to players at the guest rank or higher
local function check_promote_to_auto_trusted()
    local auto_trusted = Ranks.auto_trusted
    local guest = Ranks.guest
    local time_for_trust = trust_time
    local equal_or_greater_than = Public.equal_or_greater_than
    local equal = Public.equal
    local set_data = Server.set_data

    for index, p in pairs(guests) do
        if not p or not p.valid then
            guests[index] = nil
            return
        end

        local p_name = p.name
        if equal_or_greater_than(p_name, auto_trusted) then
            guests[index] = nil
        elseif (p.online_time > time_for_trust) and equal(p_name, guest) then
            player_ranks[p_name] = auto_trusted
            set_data(ranking_data_set, p_name, auto_trusted)
            guests[index] = nil
        elseif not p.connected then
            guests[index] = nil
        end
    end
end

--- On callback, overwrites player rank entries with data entries.
local sync_ranks_callback =
    Token.register(
    function(data)
        if not data or not data.entries then
            return
        end

        clear_table(player_ranks)
        for k, v in pairs(data.entries) do
            player_ranks[k] = v
        end
    end
)

local function on_player_joined(event)
    local index = event.player_index
    local player = Game.get_player_by_index(index)
    if not player then
        return
    end

    local player_name = player.name
    if Public.equal(player_name, Ranks.guest) then
        guests[index] = player
    end

    --- Fix for legacy name storage
    local lowerCaseName = player_name:lower()
    if player_name ~= lowerCaseName and player_ranks[lowerCaseName] then
        local player_rank = player_ranks[lowerCaseName]
        player_ranks[lowerCaseName] = nil
        player_ranks[player_name] = player_rank
        Server.set_data(ranking_data_set, lowerCaseName, nil)
        Server.set_data(ranking_data_set, player_name, player_rank)
    end
end

-- Exposed functions

--- Gets a player's rank. In cases of comparison, the appropriate functions should be used.
-- This function is exposed for the purpose of returning a numerical value for players for the
-- purposes of sorting.
-- Is the only place player.admin should be checked.
function Public.get_player_rank(player_name)
    local player = game.players[player_name]
    if player and player.valid and player.admin then
        return Ranks.admin
    elseif everyone_is_regular then
        return Ranks.regular
    end

    return player_ranks[player_name] or Ranks.guest
end
local get_player_rank = Public.get_player_rank

--- Returns the table of players in the ranking system
-- @return <table>
function Public.get_player_table()
    return player_ranks
end

--- Returns the player's rank as a name.
-- @param player_name <string>
-- @return <LocalisedString>
function Public.get_player_rank_name(player_name)
    return rank_name_lookup[get_player_rank(player_name)]
end
local get_player_rank_name = Public.get_player_rank_name

--- Returns the player's rank as a name.
-- @param player_name <string>
-- @return <table>
function Public.get_player_rank_color(player_name)
    local rank_name = get_player_rank_name(player_name)
    return Colors[rank_name]
end

--- Returns the rank's name.
-- @param rank <number>
-- @return <LocalisedString>
function Public.get_rank_name(rank)
    return rank_name_lookup[rank]
end
local get_rank_name = Public.get_rank_name

--- Returns the rank's color.
-- @param rank <table>
function Public.get_rank_color(rank)
    return Colors[rank]
end

--- Evaluates if a player's rank is equal to the rank provided
-- @param player_name <string>
-- @param rank <number>
-- @return <boolean>
function Public.equal(player_name, rank)
    local p_rank = get_player_rank(player_name)
    return p_rank == rank
end

--- Evaluates if a player's rank is not equal to the rank provided
-- @param player_name <string>
-- @param rank <number>
-- @return <boolean>
function Public.not_equal(player_name, rank)
    local p_rank = get_player_rank(player_name)
    return p_rank ~= rank
end

--- Evaluates if a player's rank is greater than the rank provided
-- @param player_name <string>
-- @param rank <number>
-- @return <boolean>
function Public.greater_than(player_name, rank)
    local p_rank = get_player_rank(player_name)
    return p_rank > rank
end

--- Evaluates if a player's rank is less than the rank provided
-- @param player_name <string>
-- @param rank <number>
-- @return <boolean>
function Public.less_than(player_name, rank)
    local p_rank = get_player_rank(player_name)
    return p_rank < rank
end

--- Evaluates if a player's rank is equal to or greater than the rank provided
-- @param player_name <string>
-- @param rank <number>
-- @return <boolean>
function Public.equal_or_greater_than(player_name, rank)
    local p_rank = get_player_rank(player_name)
    return p_rank >= rank
end

--- Evaluates if a player's rank is equal to or less than the rank provided
-- @param player_name <string>
-- @param rank <number>
-- @return <boolean>
function Public.equal_or_less_than(player_name, rank)
    local p_rank = get_player_rank(player_name)
    return p_rank <= rank
end

--- Take a player and attempts to increase their rank by 1
-- @param player_name <string>
-- @return <LocalisedString|nil> new rank name or nil if already at highest rank
function Public.increase_player_rank(player_name)
    local current_rank = (get_player_rank(player_name))
    local new_rank = change_rank_by_number(current_rank, 1)
    if current_rank == new_rank then
        return nil
    end

    local new_rank_name = rank_name_lookup[new_rank]
    set_player_rank(player_name, new_rank)
    return new_rank_name
end

--- Take a player and attempts to increase their rank to the rank provided
-- Fails if player is already higher rank
-- @param player_name <string>
-- @param rank <number>
-- @return <boolean> <LocalisedString> success/failure, and LocalisedString of the player's rank
function Public.increase_player_rank_to(player_name, rank)
    if Public.less_than(player_name, rank) then
        set_player_rank(player_name, rank)
        return true, get_rank_name(rank)
    else
        return false, get_player_rank_name(player_name)
    end
end

--- Take a player and attempts to decrease their rank by 1
-- @param player_name <string>
-- @return <LocalisedString|nil> new rank name or nil if already at lowest rank
function Public.decrease_player_rank(player_name)
    local current_rank = (get_player_rank(player_name))
    local new_rank = change_rank_by_number(current_rank, -1)
    if current_rank == new_rank then
        return nil
    end

    local new_rank_name = rank_name_lookup[new_rank]
    set_player_rank(player_name, new_rank)
    return new_rank_name
end

--- Take a player and attempts to decrease their rank to the rank provided
-- Fails if player is already lower rank
-- @param player_name <string>
-- @param rank <number>
-- @return <boolean> <LocalisedString> success/failure, and LocalisedString of the player's rank
function Public.decrease_player_rank_to(player_name, rank)
    if Public.greater_than(player_name, rank) then
        set_player_rank(player_name, rank)
        return true, get_rank_name(rank)
    else
        return false, get_player_rank_name(player_name)
    end
end

--- Sets a player's rank
-- @param player_name <string>
-- @param rank <number>
-- @return <boolean> success/failure
function Public.set_player_rank(player_name, rank)
    if Public.equal(player_name, rank) then
        return false
    elseif rank == Ranks.guest then
        player_ranks[player_name] = nil
        Server.set_data(ranking_data_set, player_name, nil)
        -- If we're dropping someone back down the guest, put them on the guests list
        local player = game.players[player_name]
        if player and player.valid then
            guests[player.index] = player
        end

        return true
    else
        player_ranks[player_name] = rank
        Server.set_data(ranking_data_set, player_name, rank)
        return true
    end
end
set_player_rank = Public.set_player_rank

--- Resets a player's rank to guest (or higher if a user meets the criteria for automatic rank)
-- @param player_name <string>
-- @return <boolean> <LocalisedString> boolean for success/failure, LocalisedString of rank name
function Public.reset_player_rank(player_name)
    local guest_rank = Ranks.guest
    local auto_trusted = Ranks.auto_trusted

    if Public.equal(player_name, guest_rank) then
        return false, get_rank_name(guest_rank)
    else
        local player = game.players[player_name]
        local rank
        if player and player.valid and (player.online_time > trust_time) then
            rank = auto_trusted
            set_player_rank(player_name, rank)
        else
            rank = guest_rank
            set_player_rank(player_name, rank)
        end
        return true, get_rank_name(rank)
    end
end

function Public.sync_ranks()
    Server.try_get_all_data(ranking_data_set, sync_ranks_callback)
end

-- Events

Event.add(defines.events.on_player_joined_game, on_player_joined)

Event.add(Server.events.on_server_started, Public.sync_ranks)

Event.on_nth_tick(nth_tick, check_promote_to_auto_trusted)

Server.on_data_set_changed(
    ranking_data_set,
    function(data)
        player_ranks[data.key] = data.value
    end
)

return Public
