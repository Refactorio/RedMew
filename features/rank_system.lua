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
local Utils = require 'utils.core'
local Server = require 'features.server'
local Ranks = require 'resources.ranks'
local Colors = require 'resources.color_presets'

local Config = global.config.rank_system

-- Localized functions
local format = string.format
local index_in_array = table.index_of_in_array

-- Constants
local ranking_data_set = 'rankings'
local nth_tick = 215983 -- nearest prime to 1 hour in ticks
local rank_name_lookup = {}

for k, v in pairs(Ranks) do
    rank_name_lookup[v] = k
end

-- Local vars
local Public = {}

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

--- Gets a player's rank. Intentionally not exposed.
local function get_player_rank(player_name)
    return player_ranks[player_name] or 0
end

--- Check each online player and if their playtime is above the required cutoff, promote them to auto-trusted.
-- Only applies to players at the guest rank or higher
local function check_promote_to_auto_trusted()
    local auto_trusted = Ranks.auto_trusted
    local guest = Ranks.guest
    local time_for_trust = Config.time_for_trust
    local equal_or_greater_than = Public.equal_or_greater_than
    local equal = Public.equal
    local set_data = Server.set_data

    for p_name in pairs(guests) do
        local p = game.players[p_name]
        if not p or not p.valid then
            return
        end

        if equal_or_greater_than(p_name, auto_trusted) then
            guests[p_name] = nil
        elseif (p.online_time > time_for_trust) and equal(p_name, guest) then
            player_ranks[p_name] = auto_trusted
            set_data(ranking_data_set, p_name, auto_trusted)
            guests[p_name] = nil
        elseif not p.online then
            guests[p_name] = nil
        end
    end
end

--- Clears the player_ranks table and merges the entries into it
local sync_ranks_callback =
    Token.register(
    function(data)
        table.clear_table(player_ranks)
        table.merge({player_ranks, data.entries})
    end
)

local function on_player_joined(event)
    local player = Game.get_player_by_index(event.player_index)
    if not player then
        return
    end
    local player_name = player.name

    if Public.equal(player_name, Ranks.guest) then
        guests[player_name] = true
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

--- Returns the player's rank as a name.
-- @param player_name <string>
-- @return <string>
function Public.get_player_rank_name(player_name)
    return rank_name_lookup[get_player_rank(player_name)]
end

--- Returns the player's rank as a name.
-- @param player_name <string>
-- @return <table>
function Public.get_player_rank_color(player_name)
    local rank_name = Public.get_player_rank_name(player_name)
    return Colors[rank_name]
end

--- Returns the rank's name.
-- @param rank <number>
-- @return <string>
function Public.get_rank_name(rank)
    return rank_name_lookup[rank]
end

--- Returns the rank's color.
-- @param rank <table>
function Public.get_rank_color(rank)
    local rank_name = Public.get_rank_name(rank)
    return Colors[rank_name]
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
-- @return <string|nil> new rank name or nil if already at highest rank
function Public.increase_player_rank(player_name)
    local new_rank = (get_player_rank(player_name) + 1)
    local new_rank_name = rank_name_lookup[new_rank]
    if new_rank_name then
        player_ranks[player_name] = (new_rank)
        return new_rank_name
    else
        return nil
    end
end

--- Take a player and attempts to decrease their rank by 1
-- @param player_name <string>
-- @return <string|nil> new rank name or nil if already at lowest rank
function Public.decrease_player_rank(player_name)
    local new_rank = (get_player_rank(player_name) - 1)
    local new_rank_name = rank_name_lookup[new_rank]
    if new_rank_name then
        player_ranks[player_name] = (new_rank)
        return new_rank_name
    else
        return nil
    end
end

--- Sets a player's rank
-- @param player_name <string>
-- @param rank <number>
function Public.set_rank(player_name, rank)
    local actor = Utils.get_actor()

    if Public.equal(player_name, rank) then
        Game.player_print(format('%s is %s rank already.', player_name, Public.get_rank_name(rank)))
    else
        player_ranks[player_name] = rank
        Server.set_data(ranking_data_set, player_name, rank)
        game.print(format("%s set %s's rank to %s.", actor, player_name, Public.get_rank_name(rank)))
    end
end

--- Resets a player's rank to the lowest rank based on playtime (guest or auto_trust)
-- @param player_name <string>
function Public.reset_rank(player_name)
    local actor = Utils.get_actor()
    local guest_rank = Ranks.guest
    local auto_trusted = Ranks.auto_trusted

    if Public.equal(player_name, guest_rank) then
        Game.player_print(format('%s is %s rank already.', player_name, Public.get_rank_name(guest_rank)))
    else
        local player = game.players[player_name]
        local rank
        if player and player.valid and (player.online_time > Config.time_for_trust) then
            player_ranks[player_name] = auto_trusted
            Server.set_data(ranking_data_set, player_name, auto_trusted)
            rank = auto_trusted
        else
            player_ranks[player_name] = nil
            Server.set_data(ranking_data_set, player_name, nil)
            rank = guest_rank
        end
        game.print(format("%s set %s's rank to %s.", actor, player_name, Public.get_rank_name(rank)))
    end
end

function Public.sync_ranks()
    Server.try_get_all_data(ranking_data_set, sync_ranks_callback)
end

-- Events

Event.add(defines.events.on_player_joined_game, on_player_joined)

Server.on_data_set_changed(
    ranking_data_set,
    function(data)
        player_ranks[data.key] = data.value
    end
)


Event.add(
    Server.events.on_server_started,
    function()
        Public.sync_rankings()
    end
)

Event.on_nth_tick(nth_tick, check_promote_to_auto_trusted)

if _DEBUG then
    --- Takes a table of old ranks, converts those ranks to correcponding entries in new_ranks and uploads everything to the upload_target dataset
    -- @param old_ranks <table> an array of ranks you want to change *from*
    -- @param new_ranks <table> an array of ranks you want to change *to*
    -- Note: old_ranks and new_ranks must have the same index key
    -- @param upload_target <string> the data set to upload to (this way you can test your migration to a dummy data set before changing the real one)
    -- @param yes_im_sure <boolean> Are you really sure you want to change the existing data set?
    function Public.migrate_data(old_ranks, new_ranks, upload_target, yes_im_sure)
        if ranking_data_set == upload_target and not yes_im_sure then
            return
        end

        for k, v in pairs(player_ranks) do
            local index = index_in_array(old_ranks, v)
            if index then
                player_ranks[k] = new_ranks[index]
            end
            Server.set_data(upload_target, k, player_ranks[k])
        end
    end
end

return Public
