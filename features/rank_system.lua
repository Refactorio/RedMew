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

local format = string.format

-- Localized functions
local index_of = table.index_of

-- Constants
local ranking_data_set = 'rankings'
local nth_tick = 215983 -- nearest prime to 1 hour in ticks

-- Local vars
local Public = {}

local player_ranks = {} -- global register

Global.register(
    {
        player_ranks = player_ranks
    },
    function(tbl)
        player_ranks = tbl.player_ranks
    end
)

-- Local functions

--- Check each online player and if their playtime
local function check_playtime()
    local auto_trusted = Ranks.auto_trusted
    local time_for_trust = Config.time_for_trust
    local less_than = Public.less_than
    local set_data = Server.set_data

    for _, p in pairs(game.connected_players) do
        local player_name = p.name
        if (p.online_time > time_for_trust) and less_than(player_name, auto_trusted) then
            player_ranks[player_name] = auto_trusted
            set_data(ranking_data_set, player_name, auto_trusted)
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

--- Fix for legacy name storage
local function on_player_joined(event)
    local player = Game.get_player_by_index(event.player_index)
    if not player then
        return
    end
    local player_name = player.name

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
    return index_of(Ranks, (player_ranks[player_name] or 0))
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
    return index_of(Ranks, rank)
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
    local p_rank = player_ranks[player_name] or 0
    return p_rank == rank
end

--- Evaluates if a player's rank is not equal to the rank provided
-- @param player_name <string>
-- @param rank <number>
-- @return <boolean>
function Public.not_equal(player_name, rank)
    local p_rank = player_ranks[player_name] or 0
    return p_rank ~= rank
end

--- Evaluates if a player's rank is greater than the rank provided
-- @param player_name <string>
-- @param rank <number>
-- @return <boolean>
function Public.greater_than(player_name, rank)
    local p_rank = player_ranks[player_name] or 0
    return p_rank > rank
end

--- Evaluates if a player's rank is less than the rank provided
-- @param player_name <string>
-- @param rank <number>
-- @return <boolean>
function Public.less_than(player_name, rank)
    local p_rank = player_ranks[player_name] or 0
    return p_rank < rank
end

--- Evaluates if a player's rank is equal to or greater than the rank provided
-- @param player_name <string>
-- @param rank <number>
-- @return <boolean>
function Public.equal_or_greater_than(player_name, rank)
    local p_rank = player_ranks[player_name] or 0
    return p_rank >= rank
end

--- Evaluates if a player's rank is equal to or less than the rank provided
-- @param player_name <string>
-- @param rank <number>
-- @return <boolean>
function Public.equal_or_less_than(player_name, rank)
    local p_rank = player_ranks[player_name] or 0
    return p_rank <= rank
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

--- Resets a player's rank
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

Event.on_nth_tick(nth_tick, check_playtime)

return Public
