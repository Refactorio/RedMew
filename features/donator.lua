-- This module contains features for donators and the permissions system for donators: who is a donator, what flags they have, adding/modifying donator data, etc.
local Event = require 'utils.event'
local Server = require 'features.server'
local Game = require 'utils.game'
local Token = require 'utils.token'
local table = require 'utils.table'
local Global = require 'utils.global'
local Task = require 'utils.task'

local concat = table.concat
local insert = table.insert
local random = math.random
local set_data = Server.set_data

local donator_data_set = 'donators'

local donators = {} -- global register

Global.register(
    {
        donators = donators
    },
    function(tbl)
        donators = tbl.donators
    end
)

local Public = {}

--- Prints the donator message with the color returned from the server
local print_after_timeout =
    Token.register(
    function(data)
        local player = data.player
        if not player.valid then
            return
        end
        game.print(data.message, player.chat_color)
    end
)

--- When a player joins, set a 1s timer to retrieve their color before printing their welcome message
local function player_joined(event)
    local player = Game.get_player_by_index(event.player_index)
    if not player or not player.valid then
        return
    end

    local d = donators[player.name]
    if not d then
        return nil
    end

    local messages = d.welcome_messages
    if not messages then
        return
    end

    local message
    local messages_type = type(messages)
    if messages_type == 'string' then
        message = messages
    elseif messages_type == 'table' then
        message = messages[random(#messages)]
    end

    message = concat({'*** ', message, ' ***'})
    Task.set_timeout_in_ticks(60, print_after_timeout, {player = player, message = message})
end

--- Returns the table of donators
-- @return <table>
function Public.get_donators_table()
    return donators
end

--- Checks if a player is a donator
-- @param player_name <string>
-- @return <boolean>
function Public.is_donator(player_name)
    return donators[player_name] ~= nil
end

--- Checks if a player has a specific donator perk
-- @param player_name <string>
-- @param perf_flag <number>
-- @return <boolean>
function Public.player_has_donator_perk(player_name, perk_flag)
    local d = donators[player_name]
    if not d then
        return false
    end

    local flags = d.perk_flags
    if not flags then
        return false
    end

    return bit32.band(flags, perk_flag) == perk_flag
end

--- Sets the data for a donator, all existing data for the entry is removed
-- @param player_name <string>
-- @param data <table>
function Public.set_donator_data(player_name, data)
    donators[player_name] = data
    set_data(donator_data_set, player_name, data)
end

--- Changes the data for a donator with any data that is sent, only overwritten data is affected
-- @param player_name <string>
-- @param data <table>
function Public.change_donator_data(player_name, data)
    for k, v in pairs(data) do
        donators[player_name][k] = v
    end

    set_data(donator_data_set, player_name, donators[player_name])
end

--- Writes the data called back from the server into the donators table, overwriting any matching entries
local sync_donators_callback =
    Token.register(
    function(data)
        for k, v in pairs(data.entries) do
            donators[k] = v
        end
    end
)

--- Signals the server to retrieve the donators data set
function Public.sync_donators()
    Server.try_get_all_data(donator_data_set, sync_donators_callback)
end

--- Prints a list of donators
function Public.print_donators()
    local result = {}

    for k, _ in pairs(donators) do
        insert(result, k)
    end

    result = concat(result, ', ')
    Game.player_print(result)
end

Event.add(
    Server.events.on_server_started,
    function()
        Public.sync_donators()
    end
)

Server.on_data_set_changed(
    donator_data_set,
    function(data)
        donators[data.key] = data.value
    end
)

Event.add(defines.events.on_player_joined_game, player_joined)

return Public
